import pytest, sys, json
import textwrap

from monopacker.template_packer import (
    merge_vars,
    get_files_from_subdirs,
    load_yaml_from_file,
    get_builders_for_templating,
    generate_packer_template,
)

def test_merge_vars():
    base = {"abc": 123, "foo": "bar", "blah": {"sub_foo": "sub_bar", "cow": "quack"}}
    override = {"abc": 456, "blah": {"cow": "moo"}}
    expected = {"abc": 456, "foo": "bar", "blah": {"sub_foo": "sub_bar", "cow": "moo"}}

    assert merge_vars(base, override) == expected


def test_merge_vars_merge_sub_dicts():
    base = {"base": 1, "combined": {"a": 1, "b": 2}}
    override = {"override": 2, "combined": {"b": 12, "c": 13}}
    expected = {"base": 1, "override": 2, "combined": {"a": 1, "b": 12, "c": 13}}

    assert merge_vars(base, override) == expected


def test_merge_vars_overwrite_arrays():
    base = {"base": 1, "both": [1, 2]}
    override = {"override": 2, "both": [3, 4]}
    expected = {"base": 1, "override": 2, "both": [3, 4]}

    assert merge_vars(base, override) == expected


def test_merge_vars_merge_sub_sub_dicts():
    base = {"combined": {"b": {1: 10, 2:20}}}
    override = {"combined": {"b": {2: 120, 3: 130}}}
    expected = {"combined": {"b": {1: 10, 2: 120, 3: 130}}}

    assert merge_vars(base, override) == expected


def test_load_yaml_from_file(tmpdir):
    p = tmpdir.mkdir("foo").join("nonexistant.yaml")
    with pytest.raises(FileNotFoundError):
        load_yaml_from_file(p)
    p.write("{}")
    y = load_yaml_from_file(p)
    assert y == {}


def test_get_builders_for_templating(tmpdir):
    builders_dir = tmpdir.mkdir("builders")
    vars_dir = tmpdir.mkdir("vars")
    scripts_dir = tmpdir.mkdir("scripts")
    builders_dir.join("foo.yaml").write(
        """
template: foo.yaml
platform: moon
builder_var_files: ["foo"]
builder_vars:
    var2: low
    var3: ohno
"""
    )
    vars_dir.join("foo.yaml").write("var1: hi\nvar3: oops")

    # tests the normal case, builder with var_files, vars
    builders = get_builders_for_templating(
        ["foo"], builders_dir=builders_dir, var_files_dir=vars_dir, scripts_dir=scripts_dir,
    )

    assert builders[0]["template"] == "foo.yaml"
    # name gets added implicitly
    assert builders[0]["vars"] == {
        "name": "foo",
        "var1": "hi",
        "var2": "low",
        "var3": "ohno",
    }

    # test builder var file does not exist
    builders_dir.join("bar.yaml").write(
        """
template: foo.yaml
platform: moon
builder_var_files: ["foo", "bar"]
builder_vars:
    var2: low

"""
    )
    # test that we get FileNotFoundError when passing a nonexistant subdir
    with pytest.raises(FileNotFoundError, match=r".*bar.yaml.*"):
        builders = get_builders_for_templating(
            ["bar"], builders_dir=builders_dir, var_files_dir=vars_dir, scripts_dir=scripts_dir,
        )


def test_get_files_from_subdirs(tmpdir):
    a = tmpdir.mkdir("ard").join("a.yaml")
    b = tmpdir.mkdir("bar").join("b.sh")
    c = tmpdir.mkdir("caz").join("c.txt")

    print(a)

    a.write("hi")
    b.write("hi")
    c.write("hi")

    # test a valid case
    files = get_files_from_subdirs("ard", "bar", "caz", root_dir=tmpdir)
    assert files == [a, b, c]

    # test specifying globs
    files = get_files_from_subdirs(
        "ard", "bar", "caz", root_dir=tmpdir, globs=["*.yaml"]
    )
    assert files == [a]
    files = get_files_from_subdirs(
        "ard", "bar", "caz", root_dir=tmpdir, globs=["*.yaml", "*.sh", "*.txt"]
    )
    assert files == [a, b, c]
    # glob does not match anything
    files = get_files_from_subdirs("ard", "bar", "caz", root_dir=tmpdir, globs=["foo"])
    assert files == []

    # test that we get FileNotFoundError when passing a nonexistant subdir
    with pytest.raises(FileNotFoundError, match=r".*bloo.*"):
        files = get_files_from_subdirs("bloo", root_dir=tmpdir)


def test_generate_packer_template(tmpdir):
    builders_dir = tmpdir.mkdir("builders")
    var_files_dir = tmpdir.mkdir("var_files")
    templates_dir = tmpdir.mkdir("templates")
    scripts_dir = tmpdir.mkdir("scripts")
    files_dir = tmpdir.mkdir("files")
    secrets_file = tmpdir.join("secrets.yml")

    builders_dir.join("linux.yaml").write(json.dumps({
        "template": "alibaba_linux",
        "platform": "linux",
        "builder_var_files": ["bv", "env"],
        "script_directories": ["facebook-worker"],
        "builder_vars": {
            "execute_command": "do-it",
            "ssh_timeout": "30m",
        },
    }))

    builders_dir.join("winny.yaml").write(json.dumps({
        "template": "openstack_windows",
        "platform": "windows",
        "builder_var_files": [],
        "script_directories": ["win-worker"],
        "builder_vars": {
            "execute_command": "do-it",
            "ssh_timeout": "30m",
        },
    }))

    templates_dir.join("alibaba_linux.jinja2").write(textwrap.dedent("""\
        - name: a packer builder
          type: alibaba
          a-is: {{builder.vars.a}}
    """))

    templates_dir.join("openstack_windows.jinja2").write(textwrap.dedent("""\
        - name: a packer builder
          type: openstack
    """))

    secrets_file.write(json.dumps([]))

    scripts_dir.mkdir("facebook-worker").join("01-fb.sh").write("echo hello")

    scripts_dir.mkdir("win-worker").join("01-win.ps1").write("ECHO hello")

    var_files_dir.join("bv.yaml").write(json.dumps({
        "a": 10,
        "b": 20,
    }))

    var_files_dir.join("env.yaml").write(json.dumps({
        "env_vars": {
            "AN_ENV_VAR": 'env!',
        },
    }))

    packer_template = generate_packer_template(
        builders=["linux", "winny"],
        builders_dir=str(builders_dir),
        var_files_dir=str(var_files_dir),
        templates_dir=str(templates_dir),
        scripts_dir=str(scripts_dir),
        files_dir=str(files_dir),
        secrets_file=str(secrets_file),
    )

    assert(packer_template == {
        'builders': [
            {
                'name': 'a packer builder',
                'type': 'alibaba',
                'a-is': 10,
            },
            {
                'name': 'a packer builder',
                'type': 'openstack',
            },
        ],
        'provisioners': [
            {
                'type': 'file',
                'source': './files.tar',
                'destination': '/tmp/',
            },
            {
                'type': 'shell',
                'inline': [
                    'sudo tar xvf /tmp/files.tar -C / --strip-components=2',
                    'rm /tmp/files.tar',
                ],
            },
            {
                'type': 'file',
                'source': './secrets.tar',
                'destination': '/tmp/',
            },
            {
                'type': 'shell',
                'inline': [
                    'sudo mkdir -p /etc/taskcluster/secrets',
                    'sudo tar xvf /tmp/secrets.tar -C /',
                    'sudo chown root:root -R /etc/taskcluster',
                    'sudo chmod 0400 -R /etc/taskcluster/secrets',
                    'rm /tmp/secrets.tar',
                ],
                'only': ['linux'],
            },
            {
                'type': 'shell',
                'inline': [
                    '/usr/bin/cloud-init status --wait',
                ],
                'only': ['linux'],
            },
            {
                'type': 'shell',
                'scripts': [str(scripts_dir.join("facebook-worker", "01-fb.sh"))],
                'environment_vars': ["AN_ENV_VAR=env!"],
                'execute_command': "do-it",
                'expect_disconnect': True,
                'start_retry_timeout': '30m',
                'only': ['linux'],
            },
            {
                'type': 'powershell',
                'scripts': [str(scripts_dir.join("facebook-worker", "01-fb.sh"))],
                'only': [],
            },
            {
                'type': 'shell',
                'scripts': [str(scripts_dir.join("win-worker", "01-win.ps1"))],
                'environment_vars': None,
                'execute_command': "do-it",
                'expect_disconnect': True,
                'start_retry_timeout': '30m',
                'only': [],
            },
            {
                'type': 'powershell',
                'scripts': [str(scripts_dir.join("win-worker", "01-win.ps1"))],
                'only': ['winny'],
            }
        ],
        'post-processors': [
            {'type': 'manifest', 'output': 'packer-artifacts.json', 'strip_path': True},
        ],
    })


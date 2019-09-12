import pytest

from monopacker.template_packer import (
    handle_vars,
    get_files_from_subdirs,
    load_yaml_from_file,
    get_builders_for_templating,
)


def test_handle_vars():
    base = {"abc": 123, "foo": "bar", "blah": {"sub_foo": "sub_bar", "cow": "quack"}}
    override = {"abc": 456, "blah": {"cow": "moo"}}
    expected = {"abc": 456, "foo": "bar", "blah": {"sub_foo": "sub_bar", "cow": "moo"}}

    assert handle_vars(base, override) == expected


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
        ["foo"], builders_dir=builders_dir, var_files_dir=vars_dir
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
            ["bar"], builders_dir=builders_dir, var_files_dir=vars_dir
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

import tarfile
import json

from monopacker.secrets import pack_secrets

def test_pack_secrets(fs):
    # "fs" is the reference to the fake file system
    fs.create_file('secrets.yaml', contents=json.dumps([
        {'name': 'a-secret', 'path': '/path/to/my/secret', 'value': 'sshh'},
        {'name': 'b-secret', 'path': '/path/to/my/stuff', 'value': 'quiet'},
    ]))
    pack_secrets('secrets.yaml', 'secrets.tar')
    with tarfile.open('secrets.tar') as tar:
        print(tar.getnames())
        # note that initial `/` is stripped
        ti = tar.extractfile('path/to/my/secret')
        assert ti.read() == b'sshh'
        ti = tar.extractfile('path/to/my/stuff')
        assert ti.read() == b'quiet'

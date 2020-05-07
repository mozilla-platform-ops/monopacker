import os
import subprocess
import tempfile

def validate(packer_template) -> bytes:
    """Run packer validate and return output.

    :param packer_template: a json packer template that will be passed to `packer validate`
    """

    with tempfile.NamedTemporaryFile(mode='w') as tmpfile:
        # write json to tmpfile

        packer_args = [
            'packer',
            'validate',
            tmpfile.path,
        ]
        try:
            res = subprocess.run(packer_args,
                                     cwd=cwd,
                                     capture_output=True,
                                     check=True)
            print(f"templated helm chart: {res.stdout.decode('utf-8')}")
            return res.stdout
        except subprocess.CalledProcessError as e:
            if e.stderr:
                print(e.stderr.decode('utf-8'))
            raise
        return res.stdout

import os
import sys
import getopt
import fileinput
import sys
import crypt

def read_password(argv):
    try:
        _, args = getopt.getopt(argv,"p")
    except getopt.GetoptError:
        sys.exit(2)
    return args[0]

old_password = os.popen("awk -F ':' '/^root/{print $2}' /etc/shadow").read().replace('\n', '')
new_password = crypt.crypt(read_password(sys.argv[1:]))
print(old_password, new_password)

for line in fileinput.input('/etc/shadow', inplace=1):
    if line.startswith('root'):
        line=line.replace(old_password,new_password)
    sys.stdout.write(line)

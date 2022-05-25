import sys
import bcrypt

password = sys.argv[1]
password = password.encode()
print(bcrypt.hashpw(password, bcrypt.gensalt()).decode())

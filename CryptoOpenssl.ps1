openssl enc -ciphers
# Speed
	openssl speed aes-128-cbc
### Encrypting a file using a symmetric cipher :
# Providing a key on the command line
echo "esse é uma mensagem que deveria ser secreta" >mesg.txt
type .\mesg.txt
openssl enc -aes-256-cbc -e -pbkdf2 -in mesg.txt -out mesg1.aes
type .\mesg1.aes
openssl enc -aes-256-cbc -d -pbkdf2 -in mesg1.aes -out mesgA.txt
type .\mesgA.txtcls
# Using a password file
# generating a symmetric key :
openssl rand -base64 256 > senha.key
type .\senha.key
type .\mesg1.aes
openssl enc -aes-256-cbc -e -kfile senha.key -pbkdf2 -in mesg.txt -out mesg2.aes
type .\mesg2.aes
openssl enc -aes-256-cbc -d -kfile senha.key -pbkdf2 -in mesg2.aes -out mesgB.txt
type .\mesgB.txt
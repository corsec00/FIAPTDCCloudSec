################# Simetrica #################
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
type .\mesgA.txt
# Using a password file
# generating a symmetric key :
openssl rand -base64 256 > senha.key
type .\senha.key
type .\mesg1.aes
openssl enc -aes-256-cbc -e -kfile senha.key -pbkdf2 -in mesg.txt -out mesg2.aes
type .\mesg2.aes
openssl enc -aes-256-cbc -d -kfile senha.key -pbkdf2 -in mesg2.aes -out mesgB.txt
type .\mesgB.txt

################# Assimétrica #################
# Gerador de Números primos
Openssl prime -generate -bits 1024

### Gerando o par RSA 
# Chave privada PrivRSA_A.key protegida por senha
openssl genpkey -aes256 -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out PrivRSA_A.key
# Chave pública PubRSA_A.pem a partir da chave privada PrivRSA_A.key
openssl pkey -in PrivRSA_A.key -out PubRSA_A.pem -pubout

# Vendo os detalhes da chave
openssl pkey -in PubRSA_A.pem -pubin –text
# Criptografando e Decriptografando
openssl rsautl -encrypt -inkey PubRSA_A.pem -pubin -in mesg.txt -out mesg_RSA-Pub.txt
openssl rsautl -decrypt -inkey PrivRSA_A.key -in mesg_RSA-Pub.txt > texto_RSA.txt


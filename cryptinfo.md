## Public-Key Cryptography

Kerckhoffs's principle states that encryption and decryption algorithms should be made public to ensure valid cryptography, i.e., "security by obscurity" is a bad idea. Obscurity gives its actor a false sense of security, believing a method is secure while it may not be. By making cryptographic algorithms public and inviting people to break them, Kerckhoffs's principle is a reflection of the scientific method and the open-source approach, which is difficult for a closed environment to compete with. If an open-source cryptographic method can withstand testing, then it is considered a strong method. RSA encryption, for example, has proven unbreakable for over four decades and is considered strong.

In public-key cryptography, both encryption (E) and decryption (D) algorithms are often made public. It is assumed that a cryptanalyst trying to break the cipher is already familiar with E and D in detail and can generate an arbitrary number of plaintext/ciphertext samples. Therefore, security is reliant on the secret key, K, and hence its length is essential so that exhaustive brute-force attempts to break it remain infeasible. Key space grows exponentially with key length. For example, if a key is limited to 2 digits only, then there are 100 possibilities to try out, but with 50 digits, there are 10<sup>50</sup> possibilities.

### Procedure

Alice generates a public key (E_A) and a private key (D_A) pair. Alice can now encrypt a plaintext message, P, using her public key, resulting in ciphertext C = E_A(P).

Alice can also apply her private key (D_A) over C to recover the original plaintext message (public/private key pairs unlock together):

D_A(C) = D_A(E_A(P)) = P

Similarly, Bob generates his own public and private keys, E_B and D_B respectivley, and can now encrypt and decrypt messages.

Assume that the public-key encryption and decryption algorithms have the property that E_A(D_A(P)) = P, in addition to the usual property that D_A(E_A(P)) = P; RSA encryption has this property.

Alice and Bob can now proceed to communicate:

* Alice shares her public key, E_A, with Bob or even publishes it on her website; however, Alice keeps her private key, D_A, secret.
* Bob also publishes his public key, E_B, and keeps his private key, D_B, secret.
* Alice wants to send a plaintext message, P, to Bob.
* Alice signs (with her private key D_A) a hashed version of P, MD(P), where MD is a message digest (e.g. SHA-1/2). Result: D_A(MD(P)).
* Alice sends D_A(MD(P)) along with plaintext P after encrypting the whole thing with Bob's public key (E_B). Result: E_B(D_A(MD(P)), P).
* Bob receives E_B(D_A(MD(P)), P) and uses his private key, D_B, to decrypt it yielding: D_A(MD(P)) and P.
* Bob reads plaintext P stating it's from Alice and that Alice used SHA-1 as MD, but Bob is still not sure it is from Alice. To authenticate, Bob uses Alice's public key, E_A, over D_A(MD(P)) yielding MD(P).
* Bob compares this found result (the MD(P) hash) to the one obtained by applying MD himself over the plaintext P that he read earlier. If the two hashes match, then he can be sure that Alice was truly the sender. This is because any intruder intercepting Alice's messages can modify P but will not be able to sign MD(P) using Alice's private key (D_A), as only Alice knows her private key.

The only problem with this is that Alice and Bob are assuming that the other person's public key is authentic. While the above setup is secure against passive intruders, it is still vulnerable to an _active_ Man-In-The-Middle (MITM) attack where the intruder can intercept and modify communications back and forth between Alice and Bob. In this case, the intruder can spoof Alice and Bob's public keys or the websites holding these, and then pretend to be Bob when communicating with Alice and vice versa. To prevent such a scenario, a trusted central authority that approves certificates for public keys is required, i.e., a trusted infra described as Public Key Infrastructure (PKI). PKI consists of many root certification authorities (CAs) distributed across the globe. These approve regional authorities (RAs) which in turn approve other smaller and smaller CAs in a hierarchy where any certificate can be traced back to a top-level CA. This is known as a "chain of trust" or certification path, and a certified entity can publish this to prove its identity to others.

## OTP Encryption

One-time pad encryption is a symmetric-key algorithm, i.e., the same key is used for both encryption and decryption. Encryption using a one-time pad (OTP) is known to be unbreakable even if the cryptanalyst has infinite compute resources and time. OTP is a very simple symmetric-key encryption method where the secret key (i.e., the one-time pad) is completely random and is known only to the communicating parties (Alice and Bob). This means that Alice and Bob have already met in person or exchanged the one-time pad via a secure, trusted channel. This requirement is a disadvantage compared to public-key encryption where there is no need for a shared key, as Alice and Bob each have their own distinct public/private key pairs.

To construct a one-time pad as a binary key:

1. Plaintext P is converted from ASCII to a binary string of 0s and 1s.
2. A one-time pad (i.e., key K) is generated consisting of a _random_ bit sequence of 0s and 1s (as long in length as P).
3. The XOR operation is computed bitwise between P and K, giving ciphertext: C = P XOR K.

Ciphertext C cannot be broken without knowledge of the key, K, because the randomness in the key means that there is no useful information that can be extracted.

Assume Bob wants to send the short message below to Alice consisting of 9 characters, i.e., 72 bits.

Message from Bob | 'I am Bob.'
:----------------|:--------------------------------------------------------------------------------
P (binary)       | 01001001 00100000 01100001 01101101 00100000 01000010 01101111 01100010 00101110
K (OTP)          | 00110100 11010011 10011100 11010000 11110000 00111100 00101110 01110001 00101111
C (binary)       | 01111101 11110011 11111101 10111101 11010000 01111110 01000001 00010011 00000001

To recover Bob's message, Alice decrypts C using the shared OTP (K), again via a XOR operation, that is Alice does: (C XOR K) to obtain P.

Bob does: C = P XOR K

Alice does: P = C XOR K

The OTP shared only by Alice and Bob can be a long random sequence of bits that each of Bob and Alice have stored on a USB or CD capable of holding Gibibytes of data. Everytime a message is sent in either direction, Bob and Alice cross out a number of bits from the OTP (which is equal to the number of bits in the exchanged message). The individual OTPs used in any message should never be used twice (as the name implies) for the following reason:

If P is encrypted with an OTP (K) yielding C1 = P XOR K, and then a second message Q is encrypted with the _same_ key, yielding C2 = Q XOR K, an eavesdropper who intercepts both C1 and C2 can simply XOR them together to obtain P XOR Q (i.e., eliminating the key K), and then has a good chance of deducing both P and Q.

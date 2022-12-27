#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>

void handleErrors(void);
int ccm_encrypt(unsigned char *plaintext, int plaintext_len,
                unsigned char *aad, int aad_len,
                unsigned char *key,
                unsigned char *iv,
                unsigned char *ciphertext,
                unsigned char *tag);
int ccm_decrypt(unsigned char *ciphertext, int ciphertext_len,
                unsigned char *aad, int aad_len,
                unsigned char *tag,
                unsigned char *key,
                unsigned char *iv,
                unsigned char *plaintext);
int main(void)
{

    char *filename = "/dev/urandom";
    const unsigned MAX_LENGTH = 1464;

    char buffer[MAX_LENGTH+16];
    int fp = open("/dev/urandom", O_RDONLY);
        read(fp, buffer,MAX_LENGTH );
    
        close(fp);

    if (fp == -1)
    {
        printf("Error: could not open file %s", filename);
        return 1;
    }

    unsigned char *key = (unsigned char *)"01234567890123456789012345678901";

    unsigned char *iv = (unsigned char *)"0123456789012345";
    size_t iv_len = 16;

    unsigned char *additional =
        (unsigned char *)"The five boxing wizards jump quickly.";

    unsigned char *ciphertext = (unsigned char*)malloc(MAX_LENGTH+16);

    unsigned char decryptedtext[128];

    unsigned char tag[16];

    int ciphertext_len;
    
    // fgets(buffer, MAX_LENGTH, fp);
    unsigned char *plaintext =
            (unsigned char *)buffer;
    unsigned char *temp;

    long count=0;
    clock_t begin = clock();
    double ts=(begin+(5*CLOCKS_PER_SEC));
    // clock_t end = clock();
    while (count<10000000)
    {   ++count;
        ciphertext_len = ccm_encrypt(plaintext, MAX_LENGTH, additional, strlen ((char *)additional), key, iv, ciphertext, tag);
        
	temp = plaintext;
        plaintext=ciphertext;
        ciphertext = temp;
       // printf("ciphertext length: %d\n",ciphertext_len);
	//printf("\nCiphertext is:\n");
       // BIO_dump_fp(stdout, (const char *)ciphertext, ciphertext_len);
       
    }
    
    clock_t end = clock();
    
    double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
    printf("\n ______BenchMarks______\n\n Latency: %f\nThroughput(Bytes/Sec):%f\nThroughput(Packets/Sec):%f\n",time_spent,(count*MAX_LENGTH)/(time_spent*1000000),count/(time_spent*1000000));
    return 0;
}

void handleErrors(void)
{
    ERR_print_errors_fp(stderr);
    abort();
}

int ccm_encrypt(unsigned char *plaintext, int plaintext_len, unsigned char *aad, int aad_len, unsigned char *key, unsigned char *iv,
                unsigned char *ciphertext, unsigned char *tag)
{
    EVP_CIPHER_CTX *ctx;

    int len;

    int ciphertext_len;


    
    if(!(ctx = EVP_CIPHER_CTX_new()))
        handleErrors();

    
    if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_ccm(), NULL, NULL, NULL))
        handleErrors();

    
    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_IVLEN, 7, NULL))
        handleErrors();

    
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_SET_TAG, 14, NULL);

    
    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv))
        handleErrors();

    
    if(1 != EVP_EncryptUpdate(ctx, NULL, &len, NULL, plaintext_len))
        handleErrors();

    
    if(1 != EVP_EncryptUpdate(ctx, NULL, &len, aad, aad_len))
        handleErrors();

   
    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
        handleErrors();
    ciphertext_len = len;

    
    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
        handleErrors();
    ciphertext_len += len;

   
    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_CCM_GET_TAG, 14, tag))
        handleErrors();

    
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}


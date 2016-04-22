#include <stdio.h>
#include <fcntl.h>
#include <string.h>

#define hex1dec(x) ((((x)>='0') && ((x)<='9')) ? ((x)-'0') : ((((x)&~0x20)>='A') && (((x)&~0x20)<='F')) ? (((x)&~0x20)-'A'+10) : exit(-1))
#define hex2dec(x) (16*(unsigned int)hex1dec((x)[0])+(unsigned int)hex1dec((x)[1]))
#define hex4dec(x) (256*hex2dec(x)+hex2dec((x)+2))

unsigned char bitmask[8192];
int finishflag = 0;

void bit_init(int finish)
{
  finishflag = finish;
  memset(bitmask, 0, sizeof(bitmask));
}

void bit_set(int addr)
{
  if (bitmask[addr >> 3] & (1 << (addr & 7)))
  {
    fprintf (stderr, "Warning: Overlay at address 0x%.4x = %d\n", addr, addr);
    if (finishflag)
      exit(-2);
  }
  else
    bitmask[addr >> 3] |= 1 << (addr & 7);
}



int main(int argc,char *argv[])
{
  int hex,tap;
  unsigned char b[4];
  unsigned int len,bytez,oldaddr,addr = -1;
  unsigned char data,chk;
  
  if (argc!=4)
    return(-1);
    
  bit_init(1);
    
  tap=open(argv[2],O_RDWR|O_CREAT|O_TRUNC,0644);

  hex=open(argv[3],O_RDONLY);
  while(read(hex,b,1)==1)
    write(tap,b,1);
  close(hex);
  
  hex=open(argv[1],O_RDONLY);
  
  while (read(hex,b,1)==1)
  {
    if (b[0]!=':' || read(hex,b,2)!=2)
      return(-1);
    len=hex2dec(b);
    if (len==0)
      break;

    if (read(hex,b,4)!=4)
      return(-1);
    oldaddr=addr;
    addr=hex4dec(b);
    if (addr!=oldaddr)
    {
      if (oldaddr!= -1)
      {
        write(tap,&chk,1);         /* chk */
        lseek(tap,-bytez-5,SEEK_CUR);
        read(tap,&chk,1);          /* chk */
        lseek(tap,-7,SEEK_CUR);
        data=bytez & 0xff;         /* len */
        chk^=data;
        write(tap,&data,1);
        data=(bytez >> 8) & 0xff;
        chk^=data;
        write(tap,&data,1);
        lseek(tap,4,SEEK_CUR);
        write(tap,&chk,1);         /* chk */
        bytez+=2;                  /* len */
        data=bytez & 0xff;
        write(tap,&data,1);
        data=(bytez >> 8) & 0xff;
        write(tap,&data,1);
        lseek(tap,0,SEEK_END);
      }
      bytez=0;
      chk=0;
      data=19;                     /* tap - block len */
      write(tap,&data,1);
      data=0;
      write(tap,&data,1);
      write(tap,&data,1);          /* block type */
      data=3;                      /* bytes */
      chk^=data;
      write(tap,&data,1);
      data='#';                    /* # */
      chk^=data;
      write(tap,&data,1);
      chk^=b[0]^b[1]^b[2]^b[3];    /* name */
      write(tap,b,4);
      data=0x20;
      chk^=data;
      write(tap,&data,1);
      write(tap,&data,1);
      write(tap,&data,1);
      write(tap,&data,1);
      write(tap,&data,1);
      write(tap,&data,1);          /* block len */
      write(tap,&data,1);
      data=addr & 0xff;            /* addr */
      chk^=data;
      write(tap,&data,1);
      data=(addr >> 8) & 0xff;
      chk^=data;
      write(tap,&data,1);
      data=0;                      /* 32768 */
      write(tap,&data,1);
      data=addr & 0x80;
      chk^=data;
      write(tap,&data,1);
      write(tap,&chk,1);           /* chk */

      write(tap,&data,1);          /* tap - block len */
      write(tap,&data,1);

      chk=0xff;                       /* block type */
      write(tap,&chk,1);
    }
    bytez+=len;
    
    if (read(hex,b,2)!=2)
      return(-1);
    
    while (len--)
    {
      bit_set(addr);
      if (read(hex,b,2)!=2)
        return(-1);
      data=(char)hex2dec(b);
      chk ^= data;
      if (write(tap,&data,1)!=1)
        return(-1);
      addr++;
    }
    
    while (read(hex,b,1)==1 && b[0]!='\n');
  }

        write(tap,&chk,1);         /* chk */
        lseek(tap,-bytez-5,SEEK_CUR);
        read(tap,&chk,1);          /* chk */
        lseek(tap,-7,SEEK_CUR);
        data=bytez & 0xff;         /* len */
        chk^=data;
        write(tap,&data,1);
        data=(bytez >> 8) & 0xff;
        chk^=data;
        write(tap,&data,1);
        lseek(tap,4,SEEK_CUR);
        write(tap,&chk,1);         /* chk */
        bytez+=2;                  /* len */
        data=bytez & 0xff;
        write(tap,&data,1);
        data=(bytez >> 8) & 0xff;
        write(tap,&data,1);
        lseek(tap,0,SEEK_END);
  
  close(tap);
  close(hex);
}
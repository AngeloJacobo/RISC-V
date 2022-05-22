# extract the text section and data section from binary file output of the compiler (RISC-V toolchain) and save the hexfile to text.bin and data.bin

import subprocess
import sys

binfile=sys.argv[1] # Second argument of caller (first argument is the script name)
objdump_cmd=f"riscv64-unknown-elf-objdump -M numeric -D {binfile} -h" # Objectdump command for RISC-V toolchain to display addresses of text and data sections


################################## EXECUTE OBJECTDUMP COMMAND ######################################
try:
    objdump_out=subprocess.run(objdump_cmd.split(),capture_output=True,text=True) # Execute OS command line with subprocess.run()
except:
    print('Objdump command failed') # command not recognized by OS
    exit()

if objdump_out.stderr != "": 
    print(objdump_out.stderr) # command recognized by OS but produces an error code output
    exit()
####################################################################################################



################ EXTRACT STARTING ADDRESS AND SIZE OF TEXT SECTION and DATA SECTION ################ 
print(objdump_out.stdout) # display output of objectdump
text_size=None
data_size=None

lines = objdump_out.stdout.splitlines() # split objdump output into array of lines

for line in lines: # analyze each lines
    if (line.find('.text') != -1) and (text_size == None): # find first occurence of word ".text"
        words = line.split()
        text_size = int(words[2],16) # size of text section
        text_start = int(words[5],16) # start address of text section in the bin file
        print('text_start: ',text_start,'\ntext_size: ',text_size)

    if (line.find('.data') != -1) and (data_size == None): # find first occurence of word ".data"
        words = line.split()
        data_size = int(words[2],16) # size of data section
        data_start = int(words[5],16) # start address of data section in the bin file
        print('data_start: ',data_start,'\ndata_size: ',data_size)

if(text_size==None): # text_size is still "None" (not updated)
    print(f'No Text Section in Bin File: {binfile}')
    exit()
    
subprocess.run(f"rm -f text.bin data.bin".split()) # delete existing occurence of text.bin and data.bin
#################################################################################################### 



################################## STORE TEXT SECTION in text.bin ################################## 
if(text_size != None):
    bin_whole=open(binfile,'rb') # read in binary format
    bin_text=open('text.bin','w') # write in text format (readable)

    bin_whole.read(text_start) # read binary file from start to text_start (do nothing)
    text=(bin_whole.read(text_size)).hex() # read binary file from text_start until the end of text section then store it (in hex format)
    for index in range(0,len(text),8): # group into eights (8 hex = 32 bits)
        instruction = text[index+6] + text[index+7] + text[index+4] + text[index+5] + text[index+2] + text[index+3] + text[index+0] + text[index+1] # order the digits to be read by "readmemh" from right to left
        bin_text.write(instruction)
        bin_text.write('\n')
#################################################################################################### 
 
 
 
 ################################## STORE DATA SECTION in data.bin ################################## 
if(data_size != None):
    bin_whole=open(binfile,'rb') # read in binary format
    bin_data=open('data.bin','w') # write in text format (readable)
    
    bin_whole.read(data_start) # read binary file from start to data_start (do nothing)
    data=(bin_whole.read(data_size)).hex() # read binary file from data_start until the end of data section then store it (in hex format)

    if(len(data)%8 != 0): # data must be 8-hex-aligned (32bits)
        data += '0'*(8 - len(data)%8) # append zeroes to make data 8-hex-aligned (32 bits)
        
    for index in range(0,len(data),8): # group into eights (8 hex = 32 bits)
        dataval = data[index+6] + data[index+7] + data[index+4] + data[index+5] + data[index+2] + data[index+3] + data[index+0] + data[index+1] # order the digits to be read by "readmemh" from right to left
        bin_data.write(dataval)
        bin_data.write('\n')
#################################################################################################### 

print("\nDONE\n")
# extract the text section and data section from binary file output of the compiler (RISC-V toolchain) and save the hexfile to memory.bin

import subprocess
import sys

binfile=sys.argv[1] # Second argument of caller is the executable file
memoryfile_output = sys.argv[2] # Third argument of caller is the memory file output where the text and data sections will be stored
objdump_cmd=f"riscv64-unknown-elf-objdump -M numeric -D {binfile} -h" # Objectdump command for RISC-V toolchain to display addresses of text and data sections
size_column = 2 # column for section size
vma_column = 3 # column for VMA 
fileoff_column = 5 # column for section file off in binary/executable file output


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



########### EXTRACT STARTING ADDRESS AND SIZE OF TEXT SECTION, GOT SECTION, DATA SECTION ############ 
# The Gnu ld documentation has the following explanation:
# "Every loadable or allocatable output section has two addresses. The
# first is the VMA, or virtual memory address. This is the address the
# section will have when the output file is run. The second is the LMA,
# or load memory address. This is the address at which the section will
# be loaded. In most cases the two addresses will be the same. An
# example of when they might be different is when a data section is
# loaded into ROM, and then copied into RAM when the program starts up
# (this technique is often used to initialize global variables in a ROM
# based system). In this case the ROM address would be the LMA, and the
# RAM address would be the VMA." 

print(objdump_out.stdout) # display output of objectdump
text_size=None
data_size=None
got_size=None

lines = objdump_out.stdout.splitlines() # split objdump output into array of lines

for line in lines: # analyze each lines
    if (line.find('.text') != -1) and (text_size == None): # find first occurence of word ".text"
        words = line.split()
        text_size = int(words[size_column],16) # size of text section
        text_vma = int(words[vma_column],16) # start address of text section in the memory
        text_fileoff = int(words[fileoff_column],16) # file off of section in the binary file
        print('text_size: ',hex(text_size),'\ntext_vma: ',hex(text_vma),'\ntext_fileoff: ',hex(text_fileoff))

    if (line.find('.data') != -1) and (data_size == None): # find first occurence of word ".data"
        words = line.split()
        data_size = int(words[size_column],16) # size of text section
        data_vma = int(words[vma_column],16) # start address of text section in the memory
        data_fileoff = int(words[fileoff_column],16) # file off of section in the binary file
        print('\ndata_size: ',hex(data_size),'\ndata_vma: ',hex(data_vma),'\ndata_fileoff: ',hex(data_fileoff))

    if (line.find('.got') != -1) and (got_size == None): # find first occurence of word ".got"
        words = line.split()
        got_size = int(words[size_column],16) # size of text section
        got_vma = int(words[vma_column],16) # start address of text section in the memory
        got_fileoff = int(words[fileoff_column],16) # file off of section in the binary file
        print('\ngot_size: ',hex(got_size),'\ngot_vma: ',hex(got_vma),'\ngot_fileoff: ',hex(got_fileoff))

if(text_size==None): # text_size is still "None" (not updated)
    print(f'No Text Section in Bin File: {binfile}')
    exit()
    
subprocess.run(f"rm -f text.bin data.bin".split()) # delete existing occurence of text.bin and data.bin
#################################################################################################### 



######################## STORE TEXT, DATA SECTION, GOT SECTION in memory.mem ####################### 
if(text_size != None):
    bin_executable=open(binfile,'rb') # read in binary format
    bin_memory=open(memoryfile_output,'w') # write in text format (readable)
    
    # Store Text Section
    blanks = text_fileoff # Number of bytes before start of text section in executable file
    bin_executable.read(blanks) # read executable file from zero to text_fileoff (do nothing)
    text=(bin_executable.read(text_size)).hex() # read executable file from start of text until the end of text section(with size of text_size) then store it (in hex format)
    blanks = text_vma # Blanks before start of text section in memory
    for index in range(0,int((blanks)/4)): # Write blanks in memory before start of text section
        bin_memory.write('00000000')
        bin_memory.write('\n')
        
    for index in range(0,len(text),8): # group into eights (8 hex = 32 bits)
        instruction = text[index+6] + text[index+7] + text[index+4] + text[index+5] + text[index+2] + text[index+3] + text[index+0] + text[index+1] # order the digits to be read by "readmemh" from right to left
        bin_memory.write(instruction)
        bin_memory.write('\n')
 
 
    # Store Data Section
    if(data_size != None):
        blanks = data_fileoff - (text_fileoff + text_size) # Number of bytes between end of text section and start of data section in executable file
        bin_executable.read(blanks) # read executable from end of text section until start of data section (do nothing)  
        data=(bin_executable.read(data_size)).hex() # read executable file from start of data until the end of data section then store it (in hex format)
        if(len(data)%8 != 0): # data must be 8-hex-aligned (32bits)
            data += '0'*(8 - len(data)%8) # append zeroes to make data 8-hex-aligned (32 bits)
        blanks = data_vma - (text_vma + text_size) # Blanks before start of data section in memory
        for index in range(0,int((blanks)/4)): # Write blanks between text and data section
            bin_memory.write('00000000')
            bin_memory.write('\n')

        for index in range(0,len(data),8): # group into eights (8 hex = 32 bits)
            dataval = data[index+6] + data[index+7] + data[index+4] + data[index+5] + data[index+2] + data[index+3] + data[index+0] + data[index+1] # order the digits to be read by "readmemh" from right to left
            bin_memory.write(dataval)
            bin_memory.write('\n')
   
    # Store GOT Section
    if(got_size != None):
        if(data_size != None): # data section exist so memory will have text+data+got sections
            blanks = got_fileoff - (data_fileoff + data_size) # Number of bytes between end of data section and start of got section in executable file
            bin_executable.read(blanks) # read executable from end of data section until start of got section (do nothing)  
            got_data=(bin_executable.read(got_size)).hex() # read executable file from start of got until the end of got section then store it (in hex format)
            if(len(got_data)%8 != 0): # got_data must be 8-hex-aligned (32bits)
                got_data += '0'*(8 - len(got_data)%8) # append zeroes to make got_data 8-hex-aligned (32 bits)
            blanks = got_vma - (data_vma + data_size) # Blanks before start of got_data section in memory

        else: # no data section does not exist so memory will only have text+got sections
            blanks = got_fileoff - (text_fileoff + text_size) # Number of bytes between end of data section and start of got section in executable file
            bin_executable.read(blanks) # read executable from end of data section until start of got section (do nothing)  
            got_data=(bin_executable.read(got_size)).hex() # read executable file from start of got until the end of got section then store it (in hex format)
            if(len(got_data)%8 != 0): # got_data must be 8-hex-aligned (32bits)
                got_data += '0'*(8 - len(got_data)%8) # append zeroes to make got_data 8-hex-aligned (32 bits)
            blanks = got_vma - (text_vma + text_size) # Blanks before start of got_data section in memory

        for index in range(0,int((blanks)/4)): # Write blanks between data and got_data section
            bin_memory.write('00000000')
            bin_memory.write('\n')

        for index in range(0,len(got_data),8): # group into eights (8 hex = 32 bits)
            dataval = got_data[index+6] + got_data[index+7] + got_data[index+4] + got_data[index+5] + got_data[index+2] + got_data[index+3] + got_data[index+0] + got_data[index+1] # order the digits to be read by "readmemh" from right to left
            bin_memory.write(dataval)
            bin_memory.write('\n')
#################################################################################################### 


print("\nDONE\n")

# HOW TO USE
# python sections.py <binfile> <memory_output>
# python sections.py test.bin memory.mem

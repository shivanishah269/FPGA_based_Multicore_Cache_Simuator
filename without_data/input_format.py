from sys import argv

def extract(filename,txt):
    output = open(filename+".txt","w+")
    output_coe = open(filename+".coe","w+")
    output_large = open(filename+"large.txt","w+")
    output_coe_large = open(filename+"large.coe","w+")
    output_binary = open(filename+"_binary.dat","w+")
    
    output_coe.write("memory_initialization_radix=16;\n")
    output_coe.write("memory_initialization_vector=\n")
    output_coe_large.write("memory_initialization_radix=16;\n")
    output_coe_large.write("memory_initialization_vector=\n")
    
    for lno,line in enumerate(txt):
        if(lno<65500):
            output.write(line.split()[1][0])
            output.write(line.split()[1][1])
            output.write(line.split()[1][6])
            output.write(line.split()[1][7])                                    
            output.write(line.split()[1][8])            
            output.write(line.split()[1][9]) 
            output.write("\n")
                       
    output.write("0x0005")        
    output.seek(0,0)
    
    for line in output.readlines():
        output_coe.write(line.split()[0][2])
        output_coe.write(line.split()[0][3])
        output_coe.write(line.split()[0][4])
        output_coe.write(line.split()[0][5])
        output_coe.write(",")
        output_coe.write("\n")
     
    output_coe.write("0005;") 
    output.seek(0,0)
    txt.seek(0,0)                   
    
    for line in txt.readlines():
        output_large.write(line.split()[1])
        output_large.write("\n")
    
    txt.seek(0,0)                   
    
    for line in txt.readlines():
        output_coe_large.write(line.split()[1][2:9])
        output_coe_large.write(",") 
        output_coe_large.write("\n")
    
    output_large.seek(0,0)
    
    for line in output_large.readlines():
        output_binary.write(bin(int(line.split()[0][2:10], 16))[2:].zfill(32))
        output_binary.write("\n")    
        
                                       
print ("Enter the filename:")
filename = input()
txt = open(filename)
extract(filename,txt)



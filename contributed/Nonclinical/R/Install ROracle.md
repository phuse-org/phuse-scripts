
Steps for installing ROracle

Install R tools
* Website: http://cran.us.r-project.org/bin/windows/Rtools/; choose proper version and build. For my window, I chose Rtools32.exe (R 3.1.x to 3.2.x).
* Instruction: https://www.biostat.wisc.edu/~kbroman/Rintro/Rwinpack.html
* Run Rtools32.exe and follow the instruction

Install ROracle
* Website: http://www.oracle.com/technetwork/database/database-technologies/r/roracle/downloads/index.html 
* Instruction: https://cran.r-project.org/web/packages/ROracle/index.html 
* Configure system parameters: 

    set OCI_INC=C:\app\product\12.1.0\client_1\oci\include
  	set OCI_LIB32=C:\app\product\12.1.0\client_1\BIN
  	set OCI_LIB64=C:\app\product\12.1.0\client_1\BIN
    Set Path to include R, RTool full path such as 
    Path=C:\app\R\Rtools\bin;C:\app\R\Rtools\gcc-4.6.3\bin;C:\Program Files\R\R-3.1.2\bin;

* Run the command in DOS prompt: R CMD INSTALL --build --merge-multiarch ROracle_1.2-1.zip

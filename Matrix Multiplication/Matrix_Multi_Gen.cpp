#include <fstream>
#include <math.h>
#include <ctime>
#include <stdlib.h>

#define N 64
#define NumUnit 1
#define W 8
#define H 8

using namespace std;

int main(){

//for(int i = 0; i < NumUnit; i++)
//{
char filename[15];
sprintf_s(filename,"Matrix_x.mif");
ofstream f(filename);
f << "DEPTH = "<<N<<";\n";
f << "WIDTH = 8;\n";
f << "ADDRESS_RADIX = HEX;\n";
f << "DATA_RADIX = HEX;\n";
f << "CONTENT\n";
f << "BEGIN\n";

char filename1[15];
sprintf_s(filename1,"Matrix_y.mif");
ofstream f1(filename1);
f1 << "DEPTH = "<<N<<";\n";
f1 << "WIDTH = 8;\n";
f1 << "ADDRESS_RADIX = HEX;\n";
f1 << "DATA_RADIX = HEX;\n";
f1 << "CONTENT\n";
f1 << "BEGIN\n";

char filename2[15];
sprintf_s(filename2,"Matrix_z.mif");
ofstream f2(filename2);
/*f2 << "DEPTH = "<<N<<";\n";
f2 << "WIDTH = 32;\n";
f2 << "ADDRESS_RADIX = HEX;\n";
f2 << "DATA_RADIX = HEX;\n";
f2 << "CONTENT\n";
f2 << "BEGIN\n";*/

int array_X[H][W];
int array_Y[H][W];
int array_Z[H][W];

for (int t =0; t < H; t++){
	for (int p = 0; p < W; p++) {
		array_X[t][p] = rand() % 256;
		array_Y[t][p] = rand() % 256;
	}
}

for (int x = 0; x < H; x++)
    {
        for (int y = 0; y < W; y++)
        {
            array_Z[x][y] = 0;
            for (int k = 0; k < W; k++)
            {
                array_Z[x][y] += array_X[x][k] * array_Y[k][y];
            }
        }
    }
for (int i =0; i < H; i++){
	for(int j =0; j < W; j++){
		
	
f  << (8*i + j)<< " : ";
f1 << (8*i + j)<< " : ";
//f2 << (8*i + j)<< " : ";
//for (int j = 0; j < 512; j++){
//int val = rand();
//int val1 = rand();
//int val2 = val + val1;
		if (array_X[i][j] < 16) {
			f << std::hex << 0;
			f << std::hex << array_X[i][j];
		}
		else {
			f << std::hex << array_X[i][j];
		}
		if (array_Y[i][j] < 16) {
			f1 << std::hex << 0;
			f1 << std::hex << array_Y[i][j];
		}
		else {
			f1 << std::hex << array_Y[i][j];
		}
		if (array_Z[i][j] < 16) {
			f2 << std::hex << 0;
			f2 << std::hex << 0;
			f2 << std::hex << 0;
			f2 << std::hex << 0;
			f2 << std::hex << array_Z[i][j];
		}
		else if ((15 < array_Z[i][j]) && (array_Z[i][j] < 256)) {
			f2 << std::hex << 0;
			f2 << std::hex << 0;
			f2 << std::hex << 0;
			f2 << std::hex << array_Z[i][j];
		}
		else if ((255 < array_Z[i][j]) && (array_Z[i][j] < 4096)) {
			f2 << std::hex << 0;
			f2 << std::hex << 0;
			f2 << std::hex << array_Z[i][j];
		}
		else if ((4095 < array_Z[i][j]) && (array_Z[i][j] < 65536)) {
			f2 << std::hex << 0;
			f2 << std::hex << array_Z[i][j];
		}
		else {
			f2 << std::hex << array_Z[i][j];
		}

/*
if (val == 0) f << "0";
if (val == 1) f << "1";
if (val == 2) f << "2";
if (val == 3) f << "3";
if (val == 4) f << "4";
if (val == 5) f << "5";
if (val == 6) f << "6";
if (val == 7) f << "7";
if (val == 8) f << "8";
if (val == 9) f << "9";
if (val == 10) f << "A";
if (val == 11) f << "B";
if (val == 12) f << "C";
if (val == 13) f << "D";
if (val == 14) f << "E";
if (val == 15) f << "F";
*/
//}
f  << ";\n";
f1 << ";\n";
f2 << "\n";
}
}
f  << "END;";
f1 << "END;";
//f2 << "END;";
//}
}

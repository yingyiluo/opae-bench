#include <fstream>
#include <math.h>
#include <ctime>
#include <stdlib.h>

#define N 64
#define NumUnit 1
#define W 8
#define H 8
#define Threshold_1 150
#define Threshold_2 20000
#define Threshold_3 80000
using namespace std;

int main() {

	//for(int i = 0; i < NumUnit; i++)
	//{
	char filename[20];
	sprintf_s(filename, "Neural_weight.mif");
	ofstream f(filename);
	f << "DEPTH = "<<N<<";\n";
	f << "WIDTH = 8;\n";
	f << "ADDRESS_RADIX = HEX;\n";
	f << "DATA_RADIX = HEX;\n";
	f << "CONTENT\n";
	f << "BEGIN\n";

	char filename1[15];
	sprintf_s(filename1, "Input.mif");
	ofstream f1(filename1);
	f1 << "DEPTH = "<<H<<";\n";
	f1 << "WIDTH = 8;\n";
	f1 << "ADDRESS_RADIX = HEX;\n";
	f1 << "DATA_RADIX = HEX;\n";
	f1 << "CONTENT\n";
	f1 << "BEGIN\n";

	char filename2[15];
	sprintf_s(filename2, "Output.mif");
	ofstream f2(filename2);
	/*f2 << "DEPTH = "<<(H+1)<<";\n";
	f2 << "WIDTH = 32;\n";
	f2 << "ADDRESS_RADIX = HEX;\n";
	f2 << "DATA_RADIX = HEX;\n";
	f2 << "CONTENT\n";
	f2 << "BEGIN\n";*/

	int array_X[H][W];
	int array_Y[H];
	int array_Z[H];

	for (int t = 0; t < H; t++) {
		array_Y[t] = rand() % 256;
		for (int p = 0; p < W; p++) {
			array_X[t][p] = rand() % 256;
		}
	}

	
		for (int x = 0; x < H; x++)
		{
			array_Z[x] = 0;
			for (int k = 0; k < W; k++)
			{
				if (array_Y[k] > Threshold_1) {
					array_Z[x] += array_X[x][k] * array_Y[k];
				}
			}
		}
		
		int Q = 0;

		for (int f = 0; f < H; f++)
		{
			if (array_Z[f] > Threshold_2)
			{
				Q = Q + array_Z[f];
			}

		}
	
		for (int i = 0; i < H; i++) {
			for (int j = 0; j < W; j++) {


				f  << (8*i + j)<< " : ";
				
				
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
				f << ";\n";
			}
		}

		for(int m = 0; m < H; m++){
			f1 << m << " : ";
			
			if (array_Y[m] < 16) {
				f1 << std::hex << 0;
				f1 << std::hex << array_Y[m];
			}
			else {
				f1 << std::hex << array_Y[m];
			}

			if (array_Z[m] > Threshold_2) {
				if (array_Z[m] < 16) {
					f2 << std::hex << 0;
					f2 << std::hex << 0;
					f2 << std::hex << 0;
					f2 << std::hex << 0;
					f2 << std::hex << array_Z[m];
				}
				else if ((15 < array_Z[m]) && (array_Z[m] < 256)) {
					f2 << std::hex << 0;
					f2 << std::hex << 0;
					f2 << std::hex << 0;
					f2 << std::hex << array_Z[m];
				}
				else if ((255 < array_Z[m]) && (array_Z[m] < 4096)) {
					f2 << std::hex << 0;
					f2 << std::hex << 0;
					f2 << std::hex << array_Z[m];
				}
				else if ((4095 < array_Z[m]) && (array_Z[m] < 65536)) {
					f2 << std::hex << 0;
					f2 << std::hex << array_Z[m];
				}
				else {
					f2 << std::hex << array_Z[m];
				}
			}
			else {
				f2 << std::hex << 0;
				f2 << std::hex << 0;
				f2 << std::hex << 0;
				f2 << std::hex << 0;
				f2 << std::hex << 0;
			}
			f1 << ";\n";
			f2 << "\n";
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
			
		}
		
		f2 << std::hex << 0;
		f2 << std::hex << 0;
		f2 << std::hex << 0;
		f2 << std::hex << 0;
		if (Q > Threshold_3)
		{
			f2 << std::hex << 1;
		}
		else
		{
			f2 << std::hex << 0;
		}
		//f << "\n";
		//f1 << "\n";
		f2 << "\n";
		f << "END;";
		f1 << "END;";
		//f2 << "END;";
	}

	
	//}


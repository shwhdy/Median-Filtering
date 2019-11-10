#include <cstdlib> // malloc(), free()
#include <iostream> // cout, stream
#include "Bitmap.h"
#include <ctime>
#include "MedianFilter.h"

#define ITERS 100

int CompareBitmaps( Bitmap* inputA, Bitmap* inputB )
{
	int x = inputA->Width();
	int y = inputA->Height();
	//char a,b;
	int count = 0;
	for(int i=0;i<x;i++)
	{
		for(int j=0;j<y;j++)
		{
			char a = inputA->GetPixel(i, j);
			char b = inputB->GetPixel(i, j);
			if(a != b)
			{
				count++;
			}
		}
	}
	return count;
}

float ComputeL2Norm( Bitmap* inputA, Bitmap* inputB )
{
	int x = inputA->Width();
	int y = inputA->Height();
	float sum = 0, delta = 0;
	unsigned char a,b;
	for(int i=0;i<x;i++)
	{
		for(int j=0;j<y;j++)
		{
			a = inputA->GetPixel(i, j);
			b = inputB->GetPixel(i, j);
			delta += (a - b) * (a - b);
			sum += (a * b);

		}
	}
	float L2norm = sqrt(delta / sum);
	return L2norm;
}

int main()
{
	float tcpu, tgpu;
	clock_t start, end;
	float L2Norm;
	int pixelcount;
	bool success;

	Bitmap InputImage;
	InputImage.Load("Lenna.bmp");
	int width = InputImage.Width();
	int height = InputImage.Height();

	std::cout<<"\nNumber of iterations: "<<ITERS<<std::endl;
	std::cout<<"operating on an image of size: "<<width<<" x "<<height<<std::endl;
	Bitmap OutputImageCPU(width,height);
	OutputImageCPU.Save("OutputImageCPU.bmp");
	Bitmap OutputImageGPU(width,height);
	OutputImageGPU.Save("OutputImageGPU.bmp");
	Bitmap OutputImageGPUShared(width,height);
	OutputImageGPU.Save("OutputImageGPUShared.bmp");
	start = clock();
	for (int i = 0; i < ITERS; i++) 
	{
		MedianFilterCPU(&InputImage,&OutputImageCPU);
	}
	end = clock();
	OutputImageCPU.Save("OutputImageCPU.bmp");
	tcpu = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC / ITERS;
	std::cout << "\nHost Computation took " << tcpu << " ms" << std::endl;

	success = MedianFilterGPU(&InputImage,&OutputImageGPU,false);
	if (!success)
	{
		std::cout << "\n * Device error! * \n" << std::endl;
		while(true);
		return -1;
	}
	start = clock();
	for (int i = 0; i < ITERS; i++) 
	{
		MedianFilterGPU(&InputImage,&OutputImageGPU,false);
	}
	end = clock();
	OutputImageGPU.Save("OutputImageGPU.bmp");
	tgpu = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC / ITERS;
	std::cout << "\nDevice Computation (global memory) took " << tgpu << " ms" << std::endl;
	pixelcount = CompareBitmaps(&OutputImageCPU,&OutputImageGPU);
	std::cout << "\nPixels differing from CPU output: " << pixelcount << std::endl;
	//std::cout <<"\nSpeedup: "<<(tcpu/tgpu)<<std::endl;
	L2Norm = ComputeL2Norm(&OutputImageCPU,&OutputImageGPU);
	std::cout << "\nError: " << L2Norm << std::endl;

	success = MedianFilterGPU(&InputImage,&OutputImageGPUShared,true);
	if (!success)
	{
		std::cout << "\n * Device error! * \n" << std::endl;
		while(true);
		return -1;
	}
	start = clock();
	for (int i = 0; i < ITERS; i++) 
	{
		MedianFilterGPU(&InputImage,&OutputImageGPUShared,true);
	}
	end = clock();
	OutputImageGPUShared.Save("OutputImageGPUShared.bmp");
	tgpu = (float)(end - start) * 1000 / (float)CLOCKS_PER_SEC / ITERS;
	std::cout << "\nDevice Computation (shared memory) took " << tgpu << " ms" << std::endl;
	pixelcount = CompareBitmaps(&OutputImageCPU,&OutputImageGPUShared);
	std::cout << "\nPixels differing from CPU output: " << pixelcount << std::endl;
	//std::cout <<"\nSpeedup: "<<(tcpu/tgpu)<<std::endl;
	L2Norm = ComputeL2Norm(&OutputImageCPU,&OutputImageGPUShared);
	std::cout << "\nError: " << L2Norm << std::endl;

	std::cout<<"\nBoom........";
	getchar();
	return 0;
}
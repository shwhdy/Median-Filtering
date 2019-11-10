#include <cuda.h>
#include <cuda_runtime_api.h>
#include <device_launch_parameters.h>
#include <algorithm> //sort
#include <vector>
#include <iostream>
#include "MedianFilter.h"

__device__ void Sort(unsigned char* array, int size)
{
	int i, key, j;
	for (i = 1; i < size; i++)
	{
		key = array[i];
		j = i - 1;
		while (j >= 0 && array[j] > key)
		{
			array[j + 1] = array[j];
			j = j - 1;
		}
		array[j + 1] = key;
	}
}


__global__ void MedianFilterSharedMemoryKernel(unsigned char* InputImage, unsigned char* OutputImage, int width, int height)
{
	__shared__ unsigned char ImagePixels[18][18];
	unsigned char PixelVals[9];
	int x = (blockIdx.x*blockDim.x) + threadIdx.x;
	int y = (blockIdx.y*blockDim.y) + threadIdx.y;
	int threadID = (y*width)+x;
	if(x < width && y < height)
	{
		
		ImagePixels[threadIdx.y+1][threadIdx.x+1] = InputImage[threadID];
		//elements of left and right columns,top and bottom rows of grid
		if(x == 0)
		{
			ImagePixels[threadIdx.y+1][threadIdx.x] = 0;
		}
		if(x == width-1)
		{
			ImagePixels[threadIdx.y+1][threadIdx.x+2] = 0;
		}
		if(y == 0)
		{
			ImagePixels[threadIdx.y][threadIdx.x+1] = 0;
		}
		if(y == height-1)
		{
			ImagePixels[threadIdx.y+2][threadIdx.x+1] = 0;
		}
		//corner elements of grid
		if(x == 0 && y == 0)
		{
			ImagePixels[threadIdx.y][threadIdx.x] = 0;
		}
		if(x == 0 && y == height-1)
		{
			ImagePixels[threadIdx.y+2][threadIdx.x] = 0;
		}
		if(x == width-1 && y == 0)
		{
			ImagePixels[threadIdx.y][threadIdx.x+2] = 0;
		}
		if(x == width-1 && y == height-1)
		{
			ImagePixels[threadIdx.y+2][threadIdx.x+2] = 0;
		}

		//left and right columns
		if(threadIdx.x == 0 && x != 0)
		{
			ImagePixels[threadIdx.y+1][threadIdx.x] = InputImage[threadID-1];
		}
		if(threadIdx.x == 15 && x != width-1)
		{
			ImagePixels[threadIdx.y+1][threadIdx.x+2] = InputImage[threadID+1];
		}

		//top and bottom rows
		if(threadIdx.y == 0 && y != 0)
		{
			ImagePixels[threadIdx.y][threadIdx.x+1] = InputImage[threadID-width];
		}
		if(threadIdx.y == 15 && y != height-1)
		{
			ImagePixels[threadIdx.y+2][threadIdx.x+1] = InputImage[threadID+width];
		}

		//corner elements
		if(threadIdx.x == 0 && threadIdx.y == 0 && x != 0 && y != 0)
		{
			ImagePixels[threadIdx.y][threadIdx.x] = InputImage[threadID-width-1];
		}
		if(threadIdx.x == 0 && threadIdx.y == 15 && x != 0 && y != height-1)
		{
			ImagePixels[threadIdx.y+2][threadIdx.x] = InputImage[threadID+width-1];
		}
		if(threadIdx.x == 15 && threadIdx.y == 0 && x != width-1 && y != 0)
		{
			ImagePixels[threadIdx.y][threadIdx.x+2] = InputImage[threadID-width+1];
		}
		if(threadIdx.x == 15 && threadIdx.y == 15 && x != width-1 && y != height-1)
		{
			ImagePixels[threadIdx.y+2][threadIdx.x+2] = InputImage[threadID+width+1];
		}
		__syncthreads();
		
		PixelVals[0] = ImagePixels[threadIdx.y+1][threadIdx.x+1];
		PixelVals[1] = ImagePixels[threadIdx.y+1][threadIdx.x];
		PixelVals[2] = ImagePixels[threadIdx.y+1][threadIdx.x+2];
		PixelVals[3] = ImagePixels[threadIdx.y][threadIdx.x+1];
		PixelVals[4] = ImagePixels[threadIdx.y][threadIdx.x];
		PixelVals[5] = ImagePixels[threadIdx.y][threadIdx.x+2];
		PixelVals[6] = ImagePixels[threadIdx.y+2][threadIdx.x+1];
		PixelVals[7] = ImagePixels[threadIdx.y+2][threadIdx.x];
		PixelVals[8] = ImagePixels[threadIdx.y+2][threadIdx.x+2];
		if(x == 0 || y == 0 || x == width-1 || y == height-1)
		{
			if(y>0 && x>0){PixelVals[4] = InputImage[threadID-width-1];}
			else{PixelVals[4] = 0;}
			if(y>0 && x<(width-1)){PixelVals[5] = InputImage[threadID-width+1];}
			else{PixelVals[5] = 0;}
			if(y<(height-1) && x>0){PixelVals[7] = InputImage[threadID+width-1];}
			else{PixelVals[7] = 0;}
			if(y<(height-1) && x<(width-1)){PixelVals[8] = InputImage[threadID+width+1];}
			else{PixelVals[8] = 0;}
		}
		Sort(PixelVals,9);
		OutputImage[threadID] = PixelVals[4];
	}
}

__global__ void MedianFilterKernel(unsigned char* InputImage, unsigned char* OutputImage, int width, int height)
{
	unsigned char PixelVals[9];
	int x = (blockIdx.x*blockDim.x) + threadIdx.x;;
	int y = (blockIdx.y*blockDim.y) + threadIdx.y;
	int threadID = (y*width)+x;
	if(x < width && y < height)
	{
		PixelVals[0] = InputImage[threadID];
		if(x>0)
		{
			PixelVals[1] = InputImage[threadID-1];
		}
		else
		{
			PixelVals[1] = 0;
		}
		if(x<(width-1))
		{
			PixelVals[2] = InputImage[threadID+1];
		}
		else
		{
			PixelVals[2] = 0;
		}
		if(y>0)
		{
			PixelVals[3] = InputImage[threadID-width];
		}
		else
		{
			PixelVals[3] = 0;
		}
		if(y>0 && x>0)
		{
			PixelVals[4] = InputImage[threadID-width-1];
		}
		else
		{
			PixelVals[4] = 0;
		}
		if(y>0 && x<(width-1))
		{
			PixelVals[5] = InputImage[threadID-width+1];
		}
		else
		{
			PixelVals[5] = 0;
		}
		if(y<(height-1))
		{
			PixelVals[6] = InputImage[threadID+width];
		}
		else
		{
			PixelVals[6] = 0;
		}
		if(y<(height-1) && x>0)
		{
			PixelVals[7] = InputImage[threadID+width-1];
		}
		else
		{
			PixelVals[7] = 0;
		}
		if(y<(height-1) && x<(width-1))
		{
			PixelVals[8] = InputImage[threadID+width+1];
		}
		else
		{
			PixelVals[8] = 0;
		}
		Sort(PixelVals,9);
		OutputImage[threadID] = PixelVals[4];
	}

}
// C Function to run matrix multiplication kernel
bool MedianFilterGPU( Bitmap* image, Bitmap* outputImage, bool sharedMemoryUse )
{

	cudaError_t status;
	int width = image->Width();
	int height = image->Height();

	int bytes = width * height * sizeof(char);
	int index =0;

	unsigned char *Md, *Pd;
	cudaMalloc((void**) &Md, bytes);
	cudaMalloc((void**) &Pd, bytes);

	cudaMemcpy(Md, image->image, bytes, cudaMemcpyHostToDevice);

	dim3 dimBlock(16, 16); 
	dim3 dimGrid((int)ceil((float)width/16), (int)ceil((float)height/16));
	if(sharedMemoryUse == false)
	{
		MedianFilterSharedMemoryKernel<<<dimGrid, dimBlock>>>(Md, Pd, width, height);
	}
	else
	{
		MedianFilterKernel<<<dimGrid, dimBlock>>>(Md, Pd, width, height);
	}
	// Wait for completion
	cudaThreadSynchronize();
	// Check for errors
	status = cudaGetLastError();
	if (status != cudaSuccess) 
	{
		std::cout << "Kernel failed: " << cudaGetErrorString(status) <<
		std::endl;
		cudaFree(Md);
		cudaFree(Pd);
		return false;
	}
	// Retrieve the result matrix
	cudaMemcpy(outputImage->image, Pd, bytes, cudaMemcpyDeviceToHost);
	index = 0;
	int pcount = 0;
	index = 0;
	cudaFree(Md);
	cudaFree(Pd);
	// Success
	return true;
}

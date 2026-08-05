using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Advanced;
using OpenCvSharp;

namespace Face_Swap
{
    internal class Data
    {
        //发过来的脸的图片
        public static Mat SourceImage = new Mat();
        //要换脸的图片名称
        public static string name;


        /// <summary>
        /// 根据图片路径将图片转成数据
        /// </summary>
        /// <param name="path">图片路径</param>
        /// <returns></returns>
        public static byte[] GetImageData(string path)
        {
            string imagePath = path;
            using (Image<Rgba32> image = SixLabors.ImageSharp.Image.Load<Rgba32>(imagePath))
            {
                var pixelMemoryGroup = image.GetPixelMemoryGroup();
                int totalPixels = image.Width * image.Height;
                float[] R = new float[image.Width * image.Height];
                float[] G = new float[image.Width * image.Height];
                float[] B = new float[image.Width * image.Height];


                int currentIndex = 0;
                foreach (var memory in pixelMemoryGroup)
                {
                    Span<Rgba32> span = memory.Span;
                    for (int i = 0; i < span.Length; i++)
                    {

                        Rgba32 pixel = span[i];
                        // 将颜色值归一化到 [0, 1] 范围
                        R[i + currentIndex] = pixel.R / 255.0f;       // R
                        G[i + currentIndex] = pixel.G / 255.0f;       // G
                        B[i + currentIndex] = pixel.B / 255.0f;       // B 

                        if (i == span.Length - 1)
                        {
                            currentIndex += span.Length;
                        }
                    }
                }

                //三合一
                float[] RGB = new float[image.Width * image.Height * 3];
                Array.Copy(R, 0, RGB, 0, R.Length);
                Array.Copy(G, 0, RGB, R.Length, G.Length);
                Array.Copy(B, 0, RGB, R.Length + G.Length, B.Length);
                //转字节
                byte[] W = BitConverter.GetBytes(image.Width);
                byte[] H = BitConverter.GetBytes(image.Height);

                byte[] rgbbyte = new byte[image.Width * image.Height * 3 * 4];
                Buffer.BlockCopy(RGB, 0, rgbbyte, 0, rgbbyte.Length);


                byte[] buffer = new byte[W.Length + H.Length + rgbbyte.Length];
                Buffer.BlockCopy(W, 0, buffer, 0, W.Length);
                Buffer.BlockCopy(H, 0, buffer, W.Length, H.Length);
                Buffer.BlockCopy(rgbbyte, 0, buffer, W.Length + H.Length, rgbbyte.Length);

                return buffer;
            }
        }

       
        public static void ProcessData(float[] RGB,int width,int height)
        {
            WriteTxt.WriteIn("进入数据转图片函数");
            int size = width * height;
            float[] interleavedRGB = new float[size * 3]; // 目标数组（交错排列）

            // 重组数据：R → G → B 变为 R/G/B 交错
            for (int i = 0; i < size; i++)
            {
                interleavedRGB[i * 3] = RGB[i];          // R
                interleavedRGB[i * 3 + 1] = RGB[i + size]; // G
                interleavedRGB[i * 3 + 2] = RGB[i + 2 * size]; // B
            }

            // 转换为 Mat（三通道浮点型）
            Mat mat = new Mat(new OpenCvSharp.Size(width, height), MatType.CV_8UC3);

            for (int y = 0; y < height; y++)
            {
                int flippedY = height - 1 - y;  // 反转行顺序
                for (int x = 0; x < width; x++)
                {
                    int dataIndex = (flippedY * width + x) * 3;

                    byte r = (byte)(Math.Clamp(interleavedRGB[dataIndex] * 255, 0, 255));
                    byte g = (byte)(Math.Clamp(interleavedRGB[dataIndex + 1] * 255, 0, 255));
                    byte b = (byte)(Math.Clamp(interleavedRGB[dataIndex + 2] * 255, 0, 255));

                    mat.Set(y, x, new Vec3b(b, g, r)); // y 从上到下，但数据来自 flippedY
                }
            }
            string outputImagePath = "output.png";
            Cv2.ImWrite(outputImagePath, mat);
            SourceImage = mat;
            WriteTxt.WriteIn("数字转图片成功");
        }
    }
}

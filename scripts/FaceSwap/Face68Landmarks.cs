using Microsoft.ML.OnnxRuntime.Tensors;
using Microsoft.ML.OnnxRuntime;
using OpenCvSharp;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Drawing;

namespace Face_Swap.Swap
{
	internal class Face68Landmarks
	{
		float[] input_image;
		int input_height;
		int input_width;
		Mat inv_affine_matrix = new Mat();

		SessionOptions options;
		InferenceSession onnx_session;

		public Face68Landmarks(string modelpath)
		{
			input_height = 256;
			input_width = 256;

			options = new SessionOptions();
			options.LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_INFO;
			options.AppendExecutionProvider_CPU(0);// 设置为CPU上运行

			// 创建推理模型类，读取本地模型文件
			onnx_session = new InferenceSession(modelpath, options);

		}

		void preprocess(Mat srcimg, Bbox bounding_box)
		{
			float sub_max = Math.Max(bounding_box.xmax - bounding_box.xmin, bounding_box.ymax - bounding_box.ymin);
			float scale = 195.0f / sub_max;
			float[] translation = new float[] { (256.0f - (bounding_box.xmax + bounding_box.xmin) * scale) * 0.5f, (256.0f - (bounding_box.ymax + bounding_box.ymin) * scale) * 0.5f };
			//python程序里的warp_face_by_translation函数////
			//Mat affine_matrix = new Mat(2, 3, MatType.CV_32FC1, new float[] { scale, 0.0f, translation[0], 0.0f, scale, translation[1] });
			Mat affine_matrix = Mat.FromPixelData(2, 3, MatType.CV_32FC1, new float[] { scale, 0.0f, translation[0], 0.0f, scale, translation[1] });
			Mat crop_img = new Mat();
			Cv2.WarpAffine(srcimg, crop_img, affine_matrix, new OpenCvSharp.Size(256, 256));
			//python程序里的warp_face_by_translation函数////
			Cv2.InvertAffineTransform(affine_matrix, inv_affine_matrix);

			Mat[] bgrChannels = Cv2.Split(crop_img);
			for (int c = 0; c < 3; c++)
			{
				bgrChannels[c].ConvertTo(bgrChannels[c], MatType.CV_32FC1, 1 / 255.0);
			}

			Cv2.Merge(bgrChannels, crop_img);

			foreach (Mat channel in bgrChannels)
			{
				channel.Dispose();
			}

			input_image = Common.ExtractMat(crop_img);
			crop_img.Dispose();
		}

		internal List<Point2f> detect(Mat srcimg, Bbox bounding_box)
		{
			//Cv2.ImShow("test", srcimg);
			preprocess(srcimg, bounding_box);

			Tensor<float> input_tensor = new DenseTensor<float>(input_image, new[] { 1, 3, input_height, input_width });
			List<NamedOnnxValue> input_container = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("input", input_tensor)
			};
			var ort_outputs = onnx_session.Run(input_container).ToArray();

			float[] pdata = ort_outputs[0].AsTensor<float>().ToArray(); //形状是(1, 68, 3), 每一行的长度是3，表示一个关键点坐标x,y和置信度
			int num_points = 68;
			List<Point2f> face_landmark_68 = new List<Point2f>();
			for (int i = 0; i < num_points; i++)
			{
				face_landmark_68.Add(new Point2f((float)(pdata[i * 3] / 64.0 * 256.0), (float)(pdata[i * 3 + 1] / 64.0 * 256.0)));
			}

			//var face_landmark_68_Points = new Mat(face_landmark_68.Count, 1, MatType.CV_32FC2, face_landmark_68.ToArray());
			var face_landmark_68_Points = Mat.FromPixelData(face_landmark_68.Count, 1, MatType.CV_32FC2, face_landmark_68.ToArray());
			Mat face68landmarks_Points = new Mat();
			Cv2.Transform(face_landmark_68_Points, face68landmarks_Points, inv_affine_matrix);

			Point2f[] face68landmarks;
			face68landmarks_Points.GetArray(out face68landmarks);

			//python程序里的convert_face_landmark_68_to_5函数////
			Point2f[] face_landmark_5of68 = new Point2f[5];
			float x = 0, y = 0;
			for (int i = 36; i < 42; i++) // left_eye
			{
				x += face68landmarks[i].X;
				y += face68landmarks[i].Y;
			}
			x /= 6;
			y /= 6;
			face_landmark_5of68[0] = new Point2f(x, y); // left_eye

			x = 0;
			y = 0;
			for (int i = 42; i < 48; i++) // right_eye
			{
				x += face68landmarks[i].X;
				y += face68landmarks[i].Y;
			}
			x /= 6;
			y /= 6;
			face_landmark_5of68[1] = new Point2f(x, y); // right_eye

			face_landmark_5of68[2] = face68landmarks[30]; // nose
			face_landmark_5of68[3] = face68landmarks[48]; // left_mouth_end
			face_landmark_5of68[4] = face68landmarks[54]; // right_mouth_end


			//// 在原图上绘制裁剪区内的68个未还原关键点并保存（用于Debug调试）
			//foreach (var face in face_landmark_68)
			//{
			//	Cv2.Circle(srcimg, (int)face.X, (int)face.Y, 2, new Scalar(0, 0, 255), -1);
			//}

			////Cv2.ImShow("test1", srcimg);
			//Cv2.ImWrite("test2.jpg", srcimg);

			////python程序里的convert_face_landmark_68_to_5函数////
			return face_landmark_5of68.ToList();
		}
	}
}

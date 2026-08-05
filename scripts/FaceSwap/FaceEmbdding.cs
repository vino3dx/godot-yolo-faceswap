using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using OpenCvSharp;
using System.Collections.Generic;
using System.Linq;

namespace Face_Swap.Swap
{
	internal class FaceEmbdding
	{

		float[] input_image;
		int input_height;
		int input_width;
		List<Point2f> normed_template = new List<Point2f>();

		SessionOptions options;
		InferenceSession onnx_session;

		public FaceEmbdding(string modelpath)
		{
			input_height = 112;
			input_width = 112;

			options = new SessionOptions();
			options.LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_INFO;
			options.AppendExecutionProvider_CPU(0);// 设置为CPU上运行

			// 创建推理模型类，读取本地模型文件
			onnx_session = new InferenceSession(modelpath, options);//model_path 为onnx模型文件的路径

			//在这里就直接定义了，没有像python程序里的那样normed_template = TEMPLATES.get(template) * crop_size
			normed_template.Add(new Point2f(38.29459984f, 51.69630032f));
			normed_template.Add(new Point2f(73.53180016f, 51.50140016f));
			normed_template.Add(new Point2f(56.0252f, 71.73660032f));
			normed_template.Add(new Point2f(41.54929968f, 92.36549952f));
			normed_template.Add(new Point2f(70.72989952f, 92.20409968f));
		}

		void preprocess(Mat srcimg, List<Point2f> face_landmark_5)
		{
			Mat crop_img = new Mat();

			Common.warp_face_by_face_landmark_5(srcimg, crop_img, face_landmark_5, normed_template, new OpenCvSharp.Size(112, 112));

			Mat[] bgrChannels = Cv2.Split(crop_img);
			for (int c = 0; c < 3; c++)
			{
				bgrChannels[c].ConvertTo(bgrChannels[c], MatType.CV_32FC1, 1 / 127.5, -1.0);
			}

			Cv2.Merge(bgrChannels, crop_img);

			foreach (Mat channel in bgrChannels)
			{
				channel.Dispose();
			}

			input_image = Common.ExtractMat(crop_img);

			crop_img.Dispose();



		}

		internal List<float> detect(Mat srcimg, List<Point2f> face_landmark_5)
		{
			preprocess(srcimg, face_landmark_5);
			Tensor<float> input_tensor = new DenseTensor<float>(input_image, new[] { 1, 3, input_height, input_width });
			List<NamedOnnxValue> input_container = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("input.1", input_tensor)
			};
			var ort_outputs = onnx_session.Run(input_container).ToArray();
			float[] pdata = ort_outputs[0].AsTensor<float>().ToArray(); // 形状是(1, 512)
			return pdata.ToList(); ;
		}
	}
}

using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using OpenCvSharp;
using System;
using System.Collections.Generic;

namespace Face_Swap.Swap
{
	internal class FaceEnhance
	{
		float[] input_image;
		int input_height;
		int input_width;
		List<Point2f> normed_template = new();
		float FACE_MASK_BLUR = 0.3f;
		int[] FACE_MASK_PADDING = new int[4] { 0, 0, 0, 0 };

		SessionOptions options;
		InferenceSession onnx_session;

		public FaceEnhance(string modelpath)
		{

			input_height = 512;
			input_width = 512;

			options = new SessionOptions();
			options.LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_INFO;
			options.AppendExecutionProvider_CPU(0);// 设置为CPU上运行

			// 创建推理模型类，读取本地模型文件
			onnx_session = new InferenceSession(modelpath, options);//model_path 为onnx模型文件的路径

			////在这里就直接定义了，没有像python程序里的那样normed_template = TEMPLATES.get(template) * crop_size
			normed_template = new List<Point2f>();
			normed_template.Add(new Point2f(192.98138112f, 239.94707968f));
			normed_template.Add(new Point2f(318.90276864f, 240.19360256f));
			normed_template.Add(new Point2f(256.63415808f, 314.01934848f));
			normed_template.Add(new Point2f(201.26116864f, 371.410432f));
			normed_template.Add(new Point2f(313.0890496f, 371.1511808f));
		}

		void preprocess(Mat srcimg, List<Point2f> face_landmark_5, ref Mat affine_matrix, ref Mat box_mask)
		{
			Mat crop_img = new Mat();
			affine_matrix = Common.warp_face_by_face_landmark_5(srcimg, crop_img, face_landmark_5, normed_template, new OpenCvSharp.Size(512, 512));
			int[] crop_size = new int[] { crop_img.Cols, crop_img.Rows };
			box_mask = Common.create_static_box_mask(crop_size, FACE_MASK_BLUR, FACE_MASK_PADDING);

			Mat[] bgrChannels = Cv2.Split(crop_img);
			for (int c = 0; c < 3; c++)
			{
				bgrChannels[c].ConvertTo(bgrChannels[c], MatType.CV_32FC1, 1 / (255.0 * 0.5), -1.0);
			}

			Cv2.Merge(bgrChannels, crop_img);

			foreach (Mat channel in bgrChannels)
			{
				channel.Dispose();
			}

			input_image = Common.ExtractMat(crop_img);
			crop_img.Dispose();
		}


		internal Mat process(Mat target_img, List<Point2f> target_landmark_5)
		{
			Mat affine_matrix = new Mat();
			Mat box_mask = new Mat();

			preprocess(target_img, target_landmark_5, ref affine_matrix, ref box_mask);

			Tensor<float> input_tensor = new DenseTensor<float>(input_image, new[] { 1, 3, input_height, input_width });
			List<NamedOnnxValue> input_container = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("input", input_tensor)
			};
			var ort_outputs = onnx_session.Run(input_container).ToArray();
			float[] pdata = ort_outputs[0].AsTensor<float>().ToArray();
			int out_h = 512;
			int out_w = 512;
			int channel_step = out_h * out_w;

			for (int i = 0; i < pdata.Length; i++)
			{
				pdata[i] = (pdata[i] + 1) * 0.5f;
				if (pdata[i] < -1)
				{
					pdata[i] = -1;
				}
				if (pdata[i] > 1)
				{
					pdata[i] = 1;
				}

				pdata[i] = pdata[i] * 255.0f;
				if (pdata[i] < 0)
				{
					pdata[i] = 0;
				}
				if (pdata[i] > 255)
				{
					pdata[i] = 255;
				}
			}

			float[] temp_b = new float[channel_step];
			float[] temp_g = new float[channel_step];
			float[] temp_r = new float[channel_step];

			Array.Copy(pdata, temp_r, channel_step);
			Array.Copy(pdata, channel_step, temp_g, 0, channel_step);
			Array.Copy(pdata, channel_step * 2, temp_b, 0, channel_step);

			//Mat rmat = new Mat(out_h, out_w, MatType.CV_32FC1, temp_r);
			Mat rmat = Mat.FromPixelData(out_h, out_w, MatType.CV_32FC1, temp_b);
			//Mat gmat = new Mat(out_h, out_w, MatType.CV_32FC1, temp_g);
			Mat gmat = Mat.FromPixelData(out_h, out_w, MatType.CV_32FC1, temp_g);
			//Mat bmat = new Mat(out_h, out_w, MatType.CV_32FC1, temp_b);
			Mat bmat = Mat.FromPixelData(out_h, out_w, MatType.CV_32FC1, temp_r);
			Mat result = new Mat();

			Cv2.Merge(new Mat[] { bmat, gmat, rmat }, result);

			result.ConvertTo(result, MatType.CV_8UC3);

			float[] box_mask_data;
			box_mask.GetArray<float>(out box_mask_data);
			int cols = box_mask.Cols;
			int rows = box_mask.Rows;
			MatType matType = box_mask.Type();

			for (int i = 0; i < box_mask_data.Length; i++)
			{
				if (box_mask_data[i] < 0)
				{
					box_mask_data[i] = 0;
				}

				if (box_mask_data[i] > 1)
				{
					box_mask_data[i] = 1;
				}
			}
			//box_mask = new Mat(rows, cols, matType, box_mask_data);
			box_mask = Mat.FromPixelData(rows, cols, matType, box_mask_data);
			Mat paste_frame = Common.paste_back(target_img, result, box_mask, affine_matrix);
			Mat dstimg = Common.blend_frame(target_img, paste_frame);
			return dstimg;
		}
	}
}

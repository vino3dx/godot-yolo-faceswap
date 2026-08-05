using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using OpenCvSharp;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;


namespace Face_Swap.Swap
{
	internal class SwapFace
	{
		float[] input_image;
		float[] input_embedding;
		int input_height;
		int input_width;
		const int len_feature = 512;
		float[] model_matrix;
		List<Point2f> normed_template;
		float FACE_MASK_BLUR = 0.3f;
		int[] FACE_MASK_PADDING = new int[4] { 0, 0, 0, 0 };
		float[] INSWAPPER_128_MODEL_MEAN = new float[3] { 0.0f, 0.0f, 0.0f };
		float[] INSWAPPER_128_MODEL_STD = new float[3] { 1.0f, 1.0f, 1.0f };

		SessionOptions options;
		InferenceSession onnx_session;

		public SwapFace(string modelpath)
		{
			input_height = 128;
			input_width = 128;

			options = new SessionOptions();
			options.LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_INFO;
			options.AppendExecutionProvider_CPU(0);// 设置为CPU上运行

			// 创建推理模型类，读取本地模型文件
			onnx_session = new InferenceSession(modelpath, options);//model_path 为onnx模型文件的路径

			normed_template = new List<Point2f>();

			normed_template.Add(new Point2f(46.29459968f, 51.69629952f));
			normed_template.Add(new Point2f(81.53180032f, 51.50140032f));
			normed_template.Add(new Point2f(64.02519936f, 71.73660032f));
			normed_template.Add(new Point2f(49.54930048f, 92.36550016f));
			normed_template.Add(new Point2f(78.72989952f, 92.20409984f));

			//读model_matrix.bin
			model_matrix = ReadFloatDataFromBinaryFile("Models/model_matrix.bin");
		}

		float[] ReadFloatDataFromBinaryFile(string filePath)
		{
			// 打开文件流和二进制读取器
			using (FileStream fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read))
			using (BinaryReader binaryReader = new BinaryReader(fileStream))
			{
				// 读取文件到float数组
				float[] floatData = new float[fileStream.Length / sizeof(float)];
				for (int i = 0; i < floatData.Length; i++)
				{
					floatData[i] = binaryReader.ReadSingle();
				}
				return floatData;
			}
		}


		Mat preprocess(Mat srcimg, List<Point2f> face_landmark_5, List<float> source_face_embedding, ref Mat affine_matrix, ref Mat box_mask)
		{
			Mat crop_img = new Mat();
			affine_matrix = Common.warp_face_by_face_landmark_5(srcimg, crop_img, face_landmark_5, normed_template, new OpenCvSharp.Size(128, 128));
			int[] crop_size = new int[2] { crop_img.Cols, crop_img.Rows };

			box_mask = Common.create_static_box_mask(crop_size, FACE_MASK_BLUR, FACE_MASK_PADDING);

			Mat[] bgrChannels = Cv2.Split(crop_img);
			for (int c = 0; c < 3; c++)
			{
				bgrChannels[c].ConvertTo(bgrChannels[c], MatType.CV_32FC1, 1 / (255.0 * INSWAPPER_128_MODEL_STD[c]), -INSWAPPER_128_MODEL_MEAN[c] / INSWAPPER_128_MODEL_STD[c]);
			}

			Cv2.Merge(bgrChannels, crop_img);

			foreach (Mat channel in bgrChannels)
			{
				channel.Dispose();
			}

			input_image = Common.ExtractMat2(crop_img);
			crop_img.Dispose();

			float linalg_norm = 0;
			for (int i = 0; i < len_feature; i++)
			{
				linalg_norm = (float)(linalg_norm + Math.Pow(source_face_embedding[i], 2));
			}
			linalg_norm = (float)Math.Sqrt(linalg_norm);

			input_embedding = new float[len_feature];
			for (int i = 0; i < len_feature; i++)
			{
				float sum = 0;
				for (int j = 0; j < len_feature; j++)
				{
					sum += (source_face_embedding[j] * model_matrix[j * len_feature + i]);
				}
				input_embedding[i] = sum / linalg_norm;
			}

			return box_mask;
		}

		internal Mat process(Mat target_img, List<float> source_face_embedding, List<Point2f> target_landmark_5)
		{
			Mat affine_matrix = new Mat();
			Mat box_mask = new Mat();

			preprocess(target_img, target_landmark_5, source_face_embedding, ref affine_matrix, ref box_mask);

			Tensor<float> input_tensor = new DenseTensor<float>(input_image, new[] { 1, 3, input_height, input_width });
			Tensor<float> input_embedding_shape = new DenseTensor<float>(input_embedding, new[] { 1, len_feature });
			List<NamedOnnxValue> input_container = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("target", input_tensor),
				NamedOnnxValue.CreateFromTensor("source", input_embedding_shape)
			};

			var ort_outputs = onnx_session.Run(input_container).ToArray();
			float[] pdata = ort_outputs[0].AsTensor<float>().ToArray();
			int out_h = 128;
			int out_w = 128;
			int channel_step = out_h * out_w;

			for (int i = 0; i < pdata.Length; i++)
			{
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

			float[] temp_r = new float[channel_step];
			float[] temp_g = new float[channel_step];
			float[] temp_b = new float[channel_step];

			Array.Copy(pdata, temp_r, channel_step);
			Array.Copy(pdata, channel_step, temp_g, 0, channel_step);
			Array.Copy(pdata, channel_step * 2, temp_b, 0, channel_step);

			//Mat rmat = new Mat(128, 128, MatType.CV_32FC1, temp_r);
			Mat rmat = Mat.FromPixelData(128, 128, MatType.CV_32FC1, temp_r);
			//Mat gmat = new Mat(128, 128, MatType.CV_32FC1, temp_g);
			Mat gmat = Mat.FromPixelData(128, 128, MatType.CV_32FC1, temp_g);
			//Mat bmat = new Mat(128, 128, MatType.CV_32FC1, temp_b);
			Mat bmat = Mat.FromPixelData(128, 128, MatType.CV_32FC1, temp_b);

			Mat result = new Mat();

			Cv2.Merge(new Mat[] { bmat, gmat, rmat }, result);

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
			Mat dstimg = Common.paste_back(target_img, result, box_mask, affine_matrix);

			return dstimg;
		}
	}
}

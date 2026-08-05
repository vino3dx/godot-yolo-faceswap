using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using OpenCvSharp;



namespace Face_Swap.Swap
{
	internal class Yolo8Face
	{
		float[] input_image;
		int input_height;
		int input_width;
		float ratio_height;
		float ratio_width;
		float conf_threshold;
		float iou_threshold;

		SessionOptions options;
		InferenceSession onnx_session;

		public Yolo8Face(string modelpath, float conf_thres = 0.5f, float iou_thresh = 0.4f)
		{
			options = new SessionOptions();
			options.LogSeverityLevel = OrtLoggingLevel.ORT_LOGGING_LEVEL_INFO;
			options.AppendExecutionProvider_CPU(0);

			// 创建推理模型类，读取本地模型文件
			onnx_session = new InferenceSession(modelpath, options);

			this.input_height = 640;
			this.input_width = 640;

			conf_threshold = conf_thres;
			iou_threshold = iou_thresh;
		}


		/// <summary>
		/// yolo8默认输入尺寸为640*640 只支持32的倍数的正方形 如果为长方形 需要拉伸和填充为正方形
		/// </summary>
		/// <param name="srcimg"></param>
		void preprocess(Mat srcimg)
		{
			int height = srcimg.Rows;
			int width = srcimg.Cols;
			Mat temp_image = srcimg.Clone();
			//如果图片像素大于640 640 保持原比例缩放
			if (height > input_height || width > input_width)
			{
				//计算比例
				float scale = Math.Min((float)input_height / height, (float)input_width / width);
				OpenCvSharp.Size new_size = new OpenCvSharp.Size((int)(width * scale), (int)(height * scale));
				Cv2.Resize(srcimg, temp_image, new_size);
			}
			ratio_height = (float)height / temp_image.Rows;
			ratio_width = (float)width / temp_image.Cols;
			Mat input_img = new Mat();
			//填充
			Cv2.CopyMakeBorder(temp_image, input_img, 0, input_height - temp_image.Rows, 0, input_width - temp_image.Cols, BorderTypes.Constant, new Scalar(0));

			//分离BGR通道
			Mat[] bgrChannels = Cv2.Split(input_img);
			//转换成32位浮点数
			for (int c = 0; c < 3; c++)
			{
				bgrChannels[c].ConvertTo(bgrChannels[c], MatType.CV_32FC1, 1 / 128.0, -127.5 / 128.0);
			}

			Cv2.Merge(bgrChannels, input_img);

			foreach (Mat channel in bgrChannels)
			{
				channel.Dispose();
			}

			input_image = Common.ExtractMat(input_img);
			input_img.Dispose();
		}

		public List<Bbox> detect(Mat srcimg)
		{
			;
			preprocess(srcimg);

			//
			Tensor<float> input_tensor = new DenseTensor<float>(input_image, new[] { 1, 3, input_height, input_width });
			List<NamedOnnxValue> input_container = new List<NamedOnnxValue>
			{
				NamedOnnxValue.CreateFromTensor("images", input_tensor)
			};

			var ort_outputs = onnx_session.Run(input_container).ToArray();
			// 形状是(1, 20, 8400),不考虑第0维batchsize，每一列的长度20,前4个元素是检测框坐标(cx,cy,w,h)，第4个元素是置信度，3

			float[] pdata = ort_outputs[0].AsTensor<float>().ToArray();
			int num_box = 8400;
			List<Bbox> bounding_box_raw = new List<Bbox>();
			List<float> score_raw = new List<float>();
			for (int i = 0; i < num_box; i++)
			{
				float score = pdata[4 * num_box + i];
				if (score > conf_threshold)
				{
					float xmin = (float)((pdata[i] - 0.5 * pdata[2 * num_box + i]) * ratio_width);            //(cx,cy,w,h)转到(x,y,w,h)并还原到原图
					float ymin = (float)((pdata[num_box + i] - 0.5 * pdata[3 * num_box + i]) * ratio_height); //(cx,cy,w,h)转到(x,y,w,h)并还原到原图
					float xmax = (float)((pdata[i] + 0.5 * pdata[2 * num_box + i]) * ratio_width);            //(cx,cy,w,h)转到(x,y,w,h)并还原到原图
					float ymax = (float)((pdata[num_box + i] + 0.5 * pdata[3 * num_box + i]) * ratio_height); //(cx,cy,w,h)转到(x,y,w,h)并还原到原图
					//坐标的越界检查保护，可以添加一下
					bounding_box_raw.Add(new Bbox(xmin, ymin, xmax, ymax));
					score_raw.Add(score);
					//剩下的5个关键点坐标的计算,暂时不写,因为在下游的模块里没有用到5个关键点坐标信息
				}
			}
			List<int> keep_inds = Common.nms(bounding_box_raw, score_raw, iou_threshold);
			//var keep_inds = new List<int>();    
			int keep_num = keep_inds.Count();
			List<Bbox> boxes = new List<Bbox>();
			for (int i = 0; i < keep_num; i++)
			{
				int ind = keep_inds[i];
				boxes.Add(bounding_box_raw[ind]);
			}
			return boxes;
		}

	}


	public class Bbox
	{
		public Bbox(float xmin, float ymin, float xmax, float ymax)
		{
			this.xmin = xmin;
			this.ymin = ymin;
			this.xmax = xmax;
			this.ymax = ymax;
		}

		public float xmin { get; set; }
		public float ymin { get; set; }
		public float xmax { get; set; }
		public float ymax { get; set; }
	}

}

using Face_Swap.Swap;
using OpenCvSharp;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Face_Swap
{
    internal class ExchangeFace
    {
        public static void Prehear()
        {
            Console.WriteLine("预热换脸模型...");
            Init();
            LoadAndCacheTemplate("Images/wedding_both.jpg");
            Console.WriteLine("换脸模型预热完成！");
        }

        private static Yolo8Face yolo8;
        private static Face68Landmarks detect_68landmarks;
        private static FaceEmbdding face_embedding;
        private static SwapFace swap_face;
        private static FaceEnhance enhance_face;

        // 🟢 新增：用于防止模型重复加载的标记
        private static bool _modelsLoaded = false;

        // 🟢 新增：模板数据的全局缓存
        private static Mat _cachedTemplateImg = null;
        private static List<Bbox> _cachedTargetBoxes = null;
        private static List<List<Point2f>> _cachedTargetLandmarks = null;

        private static void Init()
        {
            if (_modelsLoaded) return; // 如果已经加载过，直接跳过！极大地节省时间！

            Console.WriteLine("正在加载 AI 模型到内存...");
            yolo8 = new Yolo8Face("Models/yoloface_8n.onnx");
            detect_68landmarks = new Face68Landmarks("Models/2dfan4.onnx");
            face_embedding = new FaceEmbdding("Models/arcface_w600k_r50.onnx");
            swap_face = new SwapFace("Models/inswapper_128.onnx");
            enhance_face = new FaceEnhance("Models/gfpgan_1.4.onnx");
            
            _modelsLoaded = true;
            Console.WriteLine("AI 模型加载完毕！");
        }

        // =========================================================
        // 加载并缓存模板数据（仅执行一次）
        // =========================================================
        private static bool LoadAndCacheTemplate(string fullname)
        {
            if (_cachedTemplateImg != null && !_cachedTemplateImg.Empty())
                return true; // 已经缓存过了

            Console.WriteLine("正在预计算模板人脸数据...");

            if (!File.Exists(fullname))
            {
                Console.WriteLine("目标路径图片不存在: " + fullname);
                return false;
            }

            _cachedTemplateImg = Cv2.ImRead(fullname);

            if (_cachedTemplateImg.Empty())
            {
                Console.WriteLine("目标模板图片为空: " + fullname);
                return false;
            }

            _cachedTargetBoxes = yolo8.detect(_cachedTemplateImg);

            if (_cachedTargetBoxes.Count < 2)
            {
                Console.WriteLine("模板未检测到两张人脸！");
                return false;
            }

            // 排序：左男，右女
            _cachedTargetBoxes = SortFacesFromLeftToRight(_cachedTargetBoxes);

            // 🟢 极其关键：提前算出模板的两张脸的 68 关键点，后续再也不用算了
            _cachedTargetLandmarks = new List<List<Point2f>>();
            foreach (var box in _cachedTargetBoxes)
            {
                _cachedTargetLandmarks.Add(detect_68landmarks.detect(_cachedTemplateImg, box));
            }

            Console.WriteLine("模板人脸数据预计算并缓存成功！");
            return true;
        }

        public static string Swap(Mat sourceImg)
        {
            WriteTxt.WriteIn("进入换脸环节");
            Console.WriteLine("进入换脸环节");

            // 1. 初始化模型（只会真实执行一次）
            Init();

            // 2. 初始化模板缓存（只会真实执行一次）
            string fullname = "Images/wedding_both.jpg";
            if (!LoadAndCacheTemplate(fullname))
            {
                WriteTxt.WriteIn("模板加载或解析失败");
                return string.Empty;
            }

            // 🟢 拷贝一份缓存的模板图用于本次修改（防止污染原图）
            Mat targetImg = _cachedTemplateImg.Clone();

            // =========================================================
            // 3. 检测用户照片中的人脸
            // =========================================================
            List<Bbox> sourceBoxes = yolo8.detect(sourceImg);
            if (sourceBoxes.Count == 0)
            {
                Console.WriteLine("未检测到人脸");
                WriteTxt.WriteIn("未检测到人脸");
                return string.Empty;
            }
            sourceBoxes = SortFacesFromLeftToRight(sourceBoxes);

            // =========================================================
            // 4. 执行换脸逻辑（直接使用缓存的 _cachedTargetLandmarks）
            // =========================================================
            if (Data.name == "male")
            {
                if (sourceBoxes.Count < 1) return string.Empty;
                targetImg = SwapOneFace(sourceImg, targetImg, sourceBoxes[0], _cachedTargetLandmarks[0]);
            }
            else if (Data.name == "female")
            {
                if (sourceBoxes.Count < 1) return string.Empty;
                targetImg = SwapOneFace(sourceImg, targetImg, sourceBoxes[0], _cachedTargetLandmarks[1]);
            }
            else if (Data.name == "both")
            {
                if (sourceBoxes.Count < 2)
                {
                    throw new Exception("双人模式：请两人一起入镜");
                }
                
                // 左边男生 -> 使用缓存的模板左脸关键点
                targetImg = SwapOneFace(sourceImg, targetImg, sourceBoxes[0], _cachedTargetLandmarks[0]);
                // 右边女生 -> 使用缓存的模板右脸关键点
                targetImg = SwapOneFace(sourceImg, targetImg, sourceBoxes[1], _cachedTargetLandmarks[1]);
            }
            else
            {
                return string.Empty;
            }

            // =========================================================
            // 5. 保存最终结果
            // =========================================================
            string picturesPath = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
            string appFolderPath = Path.Combine(picturesPath, "MyCameraApp");
            Directory.CreateDirectory(appFolderPath);
            string imagePath = Path.Combine(appFolderPath, "swapimg.jpg");

            Cv2.ImWrite(imagePath, targetImg);

            WriteTxt.WriteIn("换脸完毕");
            Console.WriteLine("换脸完毕: " + imagePath);

            // 🟢 释放本次克隆的内存，避免内存泄漏
            targetImg.Dispose(); 

            return imagePath;
        }

        // =============================================================
        // 单张脸换脸（修改参数：直接传入计算好的 targetLandmarks）
        // =============================================================
        private static Mat SwapOneFace(
            Mat sourceImg,
            Mat currentTarget,
            Bbox sourceBox,
            List<Point2f> targetLandmarks) // 🟢 修改：直接接收传进来的缓存关键点
        {
            // 提取用户的关键点与特征
            List<Point2f> sourceLandmarks = detect_68landmarks.detect(sourceImg, sourceBox);
            List<float> sourceEmbedding = face_embedding.detect(sourceImg, sourceLandmarks);

            // 换脸（直接使用缓存的 targetLandmarks）
            Mat swapping0 = swap_face.process(currentTarget, sourceEmbedding, targetLandmarks);

            // 增强（直接使用缓存的 targetLandmarks）
            Mat swapping = enhance_face.process(swapping0, targetLandmarks);

            // 释放中间变量内存
            swapping0.Dispose();

            return swapping;
        }

        // =============================================================
        // 辅助方法
        // =============================================================
        private static List<Bbox> SortFacesFromLeftToRight(List<Bbox> boxes)
        {
            return boxes.OrderBy(box => GetFaceCenterX(box)).ToList();
        }

        private static float GetFaceCenterX(Bbox box)
        {
            return (box.xmin + box.xmax) * 0.5f;
        }
    }
}
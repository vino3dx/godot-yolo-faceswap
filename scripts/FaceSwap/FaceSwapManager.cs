using Godot;
using System;
using System.Threading.Tasks;
using OpenCvSharp;
using Face_Swap; // 换成你实际的命名空间

// 负责持有 5 个模型（只加载一次），暴露一个方法给 GDScript 调用;挂载为 Autoload 单例（Project Settings -> Autoload）

public partial class FaceSwapManager : Node
{
	// 换脸完成信号：GDScript 里用 FaceSwapManager.SwapCompleted.connect(_on_swap_completed) 监听
	[Signal]
	public delegate void SwapCompletedEventHandler(string resultPath, bool success, string errorMessage);

	private bool _isProcessing = false;

	public override void _Ready()
	{
		GD.Print("FaceSwapManager 已就绪");

		// 🚀 在软件启动的第一时间，开启后台异步线程预热 AI 引擎！
		Task.Run(() =>
		{
			ExchangeFace.Prehear();
			GD.Print("✅ [后台线程] AI 换脸引擎预热完成，随时就绪！");
		});
	}

	/// <summary>
	/// 供 GDScript 调用：发起一次换脸请求
	/// </summary>
	/// <param name="sourceImagePath">真实文件系统路径（不是 user://），拍照得到的用户脸照片</param>
	/// <param name="templateName">对应 Images/{templateName}.jpg 的模板名（不带后缀）</param>
	public void RequestSwap(string sourceImagePath, string templateName)
	{
		if (_isProcessing)
		{
			GD.PrintErr("已有一个换脸任务在处理中，忽略本次请求");
			return;
		}

		_isProcessing = true;

		_ = RunSwapAsync(sourceImagePath, templateName);
	}

	private async Task RunSwapAsync(string sourceImagePath, string templateName)
	{
		string resultPath = string.Empty;
		bool success = false;
		string errorMessage = string.Empty;

		try
		{
			resultPath = await Task.Run(() =>
			{
				Mat sourceMat = Cv2.ImRead(sourceImagePath);
				if (sourceMat.Empty())
				{
					throw new Exception($"源图片读取失败: {sourceImagePath}");
				}

				Data.name = templateName;
				return ExchangeFace.Swap(sourceMat);
			});

			success = !string.IsNullOrEmpty(resultPath) && System.IO.File.Exists(resultPath);
			if (!success)
			{
				errorMessage = "未检测到人脸，或换脸处理失败";
			}
		}
		catch (Exception ex)
		{
			success = false;
			errorMessage = ex.Message;
			GD.PrintErr($"换脸出错: {ex}");
		}

		_isProcessing = false;

		// 必须用 CallDeferred 切回主线程再发信号，Task.Run 的延续可能在其他线程上
		CallDeferred(nameof(EmitSwapCompleted), resultPath, success, errorMessage);
	}

	private void EmitSwapCompleted(string resultPath, bool success, string errorMessage)
	{
		EmitSignal(SignalName.SwapCompleted, resultPath, success, errorMessage);
	}
}

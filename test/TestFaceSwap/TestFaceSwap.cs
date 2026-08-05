using Godot;
using System;
using System.Threading.Tasks;
using OpenCvSharp;
using Face_Swap; // 换成你实际改过的命名空间

public partial class TestFaceSwap : Control
{
	private Button _btnSwap;
	private TextureRect _resultDisplay;

	public override void _Ready()
	{
		_btnSwap = GetNode<Button>("BtnSwap");
		_resultDisplay = GetNode<TextureRect>("ResultDisplay");

		_btnSwap.Pressed += OnSwapPressed;
	}

	private async void OnSwapPressed()
	{
		_btnSwap.Disabled = true;
		_btnSwap.Text = "换脸中...";

		// 换成你自己电脑上一张真实存在的人脸照片路径（source：提供人脸身份的那张）
		string sourcePath = "D:/Projects/DaBaShan/hun_jia_xi_su/Images/test_source.jpg";

		// target 模板名，对应 Images/test_target.jpg（不带后缀）
		Data.name = "wedding_template";

		string resultPath = string.Empty;

		try
		{
			// 推理很重，扔到后台线程，避免卡住UI
			resultPath = await Task.Run(() =>
			{
				Mat sourceMat = Cv2.ImRead(sourcePath);
				if (sourceMat.Empty())
				{
					GD.PrintErr($"源图片读取失败: {sourcePath}");
					return string.Empty;
				}
				return ExchangeFace.Swap(sourceMat);
			});
		}
		catch (Exception ex)
		{
			GD.PrintErr($"换脸过程出错: {ex}");
		}

		if (!string.IsNullOrEmpty(resultPath) && System.IO.File.Exists(resultPath))
		{
			GD.Print($"换脸成功，结果保存于: {resultPath}");

			var img = new Godot.Image();
			var err = img.Load(resultPath);
			if (err == Error.Ok)
			{
				var tex = ImageTexture.CreateFromImage(img);
				_resultDisplay.Texture = tex;
			}
			else
			{
				GD.PrintErr($"结果图片加载失败: {err}");
			}
		}
		else
		{
			GD.PrintErr("换脸失败，未生成结果图片（可能未检测到人脸，看上面的Debug信息）");
		}

		_btnSwap.Disabled = false;
		_btnSwap.Text = "测试换脸";
	}
}

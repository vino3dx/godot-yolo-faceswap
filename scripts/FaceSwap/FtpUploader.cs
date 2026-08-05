using Godot;
using System;
using System.Net;
using System.Threading.Tasks;

// Autoload 单例，跟 FaceSwapManager 用同一套模式：
// GDScript 调用 RequestUpload 发起请求，不做跨语言 await，
// 完成后通过 Godot 信号 UploadCompleted 通知结果，避免 async Task 跨语言调用的兼容性问题
public partial class FtpUploader : Node
{
	[Signal]
	public delegate void UploadCompletedEventHandler(bool success, string url, string errorMessage);

	private string ftpServerIp = "poso.gotoftp11.com";
	private string ftpUser = "poso";
	private string ftpPass = "Mzkj.666";
	private string remoteFolder = "/wwwroot/image/bazhognjianchayuan/";
	// 固定文件名，同名覆盖替换（不生成唯一文件名，不生成二维码）
	// 注意：必须跟其他程序（如Unity端）用的文件名区分开，避免互相覆盖影响
	private const string TARGET_FILE_NAME = "wedding.jpg";

	// 上传成功后，供访问的公网HTTP地址前缀
	// 域名参考了同一FTP服务器上已验证可用的地址
	private string publicHttpBaseUrl = "http://shader.show/image/bazhognjianchayuan/";

	private bool _isUploading = false;

	/// <summary>
	/// 供 GDScript 调用：发起一次上传请求，不阻塞、不需要 await
	/// </summary>
	public void RequestUpload(Image image)
	{
		if (_isUploading)
		{
			GD.PrintErr("已有上传任务在进行，忽略本次请求");
			return;
		}
		if (image == null || image.IsEmpty())
		{
			CallDeferred(nameof(EmitUploadCompleted), false, "", "图片为空");
			return;
		}

		_isUploading = true;
		_ = RunUploadAsync(image);
	}

	private async Task RunUploadAsync(Image image)
	{
		bool success = false;
		string url = string.Empty;
		string errorMessage = string.Empty;

		try
		{
			byte[] fileData = image.SaveJpgToBuffer();
			string fullFtpPath = $"ftp://{ftpServerIp}{remoteFolder}{TARGET_FILE_NAME}";

			await Task.Run(() =>
			{
				var request = (FtpWebRequest)WebRequest.Create(fullFtpPath);
				request.Method = WebRequestMethods.Ftp.UploadFile;
				request.Credentials = new NetworkCredential(ftpUser, ftpPass);
				request.UseBinary = true;
				request.UsePassive = true;
				request.ContentLength = fileData.Length;

				using (var requestStream = request.GetRequestStream())
				{
					requestStream.Write(fileData, 0, fileData.Length);
				}
				using (var response = (FtpWebResponse)request.GetResponse())
				{
					GD.Print($"[FTP] 上传成功: {response.StatusDescription}");
				}
			});

			success = true;
			url = publicHttpBaseUrl + TARGET_FILE_NAME;
		}
		catch (Exception e)
		{
			success = false;
			errorMessage = e.Message;
			GD.PrintErr($"[FTP] 上传失败: {e.Message}");
		}

		_isUploading = false;

		// 必须用 CallDeferred 切回主线程再发信号
		CallDeferred(nameof(EmitUploadCompleted), success, url, errorMessage);
	}

	private void EmitUploadCompleted(bool success, string url, string errorMessage)
	{
		EmitSignal(SignalName.UploadCompleted, success, url, errorMessage);
	}
}

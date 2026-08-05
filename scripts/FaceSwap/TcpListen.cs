using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Net.Sockets;
using System.Net;
using OpenCvSharp;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Advanced;

namespace Face_Swap
{
	internal class TcpListen
	{
		public static string Ip;
		public static TcpClient client;
		public static async Task Listen()
		{
			TcpListener listener;
			try
			{
				IPAddress iPAddress = IPAddress.Any;
				IPEndPoint IPEndPoint = new IPEndPoint(iPAddress, 60000);
				listener = new TcpListener(IPEndPoint);
				listener.Start();
				Console.WriteLine("正在监听中");
				WriteTxt.WriteIn("正在监听中");
				client = await listener.AcceptTcpClientAsync();
				Console.WriteLine("连接成功");
				Console.WriteLine($"当前连接的IP地址为{client.Client.RemoteEndPoint.ToString()}");
				//接收消息18;
				await Receive(client);
			}
			catch
			{
				Console.WriteLine("连接失败");
				return;
			}
		}


		public static async Task Receive(TcpClient client)
		{
			NetworkStream stream = client.GetStream();
			byte[] headbuffer = new byte[12];
			try
			{
				while (client.Connected)
				{
					if (await ReadExactAsync(stream, headbuffer, 0, headbuffer.Length) != 12)
					{
						Console.WriteLine("头部数据长度不符");
						WriteTxt.WriteIn("头部数据长度不符");
						break;
					}

					int W = BitConverter.ToInt32(headbuffer, 0);
					int H = BitConverter.ToInt32(headbuffer, 4);
					int nameLenth = BitConverter.ToInt32(headbuffer, 8);
					if (W <= 0 || H <= 0)
					{
						return;
					}
					Console.WriteLine($"当前图片宽为{W}，高为{H},图片名称长度为{nameLenth}");
					WriteTxt.WriteIn($"当前图片宽为{W}，高为{H},图片名称长度为{nameLenth}");

					//读取图片名称
					byte[] bodyBuffer = new byte[nameLenth];

					if (await ReadExactAsync(stream, bodyBuffer, 0, bodyBuffer.Length) != bodyBuffer.Length)
					{
						Console.WriteLine("身体数据长度不符");
						WriteTxt.WriteIn("身体数据长度不符");
						break;
					}

					Data.name = Encoding.UTF8.GetString(bodyBuffer);
					Console.WriteLine($"图片名称为{Data.name}");


					string picturesPath = System.Environment.GetFolderPath(System.Environment.SpecialFolder.MyPictures);
					string appFolderPath = Path.Combine(picturesPath, "MyCameraApp");
					string imagePath = Path.Combine(appFolderPath, "photo.jpg");

					if (!File.Exists(imagePath))
					{
						Console.WriteLine($"图片路径不存在{imagePath}");
						return;
					}

					Mat mat = Cv2.ImRead(imagePath);

					//数据处理换脸(会保存一张图片)
					string fullname = ExchangeFace.Swap(mat);

					//发送
					if (fullname != string.Empty)
					{
						byte[] buffer = Encoding.UTF8.GetBytes("换脸完成");
						await stream.WriteAsync(buffer, 0, buffer.Length);
						Console.WriteLine("发送成功");
					}
					else
					{
						//byte[] buffer = Encoding.UTF8.GetBytes("未检测到人脸");
						byte[] w = BitConverter.GetBytes(-1);
						byte[] h = BitConverter.GetBytes(-1);
						byte[] buffer = new byte[w.Length + h.Length];
						Buffer.BlockCopy(w, 0, buffer, 0, w.Length);
						Buffer.BlockCopy(h, 0, buffer, w.Length, h.Length);
						await stream.WriteAsync(buffer, 0, buffer.Length);
					}
				}
			}
			catch (IOException ex) when (ex.InnerException is SocketException socketEx)
			{
				// 连接被重置、断开等
				Console.WriteLine("客户端异常断开: " + socketEx.SocketErrorCode);
				WriteTxt.WriteIn("客户端异常断开: " + socketEx.SocketErrorCode);
			}
			catch (ObjectDisposedException)
			{
				Console.WriteLine("连接已关闭（可能被显式关闭）");
				WriteTxt.WriteIn("连接已关闭可能被显式关闭");
			}
			catch (SocketException ex)
			{
				switch (ex.SocketErrorCode)
				{
					case SocketError.ConnectionReset:
						Console.WriteLine("连接被对端重置");
						WriteTxt.WriteIn("连接被对端重置");
						break;
					case SocketError.ConnectionAborted:
						Console.WriteLine("连接被终止");
						WriteTxt.WriteIn("连接被终止");
						break;
					case SocketError.TimedOut:
						// 连接超时（可能网络问题、对端无响应）
						Console.WriteLine("连接超时 (Connection timed out).");
						WriteTxt.WriteIn("连接超时 (Connection timed out)");
						break;
					case SocketError.Shutdown:
						Console.WriteLine("套接字已关闭");
						WriteTxt.WriteIn("套接字已关闭");
						break;
					default:
						Console.WriteLine($"Socket 错误:{ex.SocketErrorCode} 代码:{ex.ErrorCode}");
						WriteTxt.WriteIn($"Socket 错误:{ex.SocketErrorCode} 代码:{ex.ErrorCode}");
						break;
				}
			}
			finally
			{
				client?.Close();
				Console.WriteLine("资源已释放");
			}
		}

		public static async Task<int> ReadExactAsync(Stream stream, byte[] buffer, int offset, int count)
		{
			int totalRead = 0;
			while (totalRead < count)
			{
				int bytesRead = await stream.ReadAsync(buffer, offset + totalRead, count - totalRead);
				if (bytesRead == 0) // 客户端断开
					return totalRead == 0 ? -1 : totalRead; // 返回 -1 表示连接关闭
				totalRead += bytesRead;
			}
			return totalRead;
		}


	}

}

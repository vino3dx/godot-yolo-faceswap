using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Face_Swap
{

    public  class WriteTxt
    {
        public static void WriteIn(string content)
        {
            using (StreamWriter writer = new StreamWriter("Debug.txt", append: true, Encoding.UTF8))
            {
                writer.WriteLine(content);
            }
        }
    }
}

require 'rspec/autorun'
require 'matrix'
require 'pry'

class MyJPEG
  # @param mpixels [Matrix]
  attr_accessor :mpixels, :file_size, :first_pixel, :file_data
  attr_reader :T, :Q50
  def initialize(file)
    @file_data = File.read(file).split
    @mpixels = @file_data.dup
    @dctpixels = []
    @file_size = @file_data[10]
    @first_pixel = 12
    @T = Matrix[[0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536],
                [0.4904, 0.4157, 0.2778, 0.0975, -0.0975, -0.2778, -0.4157, -0.4904],
                [0.4619, 0.1913, -0.1913, -0.4619, -0.4619, -0.1913, 0.1913, 0.4619],
                [0.4157, -0.0975, -0.4904, -0.2778, 0.2778, 0.4904, 0.0975, -0.4157],
                [0.3536, -0.3536, -0.3536, 0.3536, 0.3536, -0.3536, -0.3536, 0.3536],
                [0.2778, 0.4904, 0.0975, 0.4157, -0.4157, -0.0975, -0.4904, -0.2778],
                [0.1913, -0.4619, 0.4619, -0.1913, -0.1913, 0.4619, -0.4619, 0.1913],
                [0.0975, -0.2778, 0.4157, -0.4904, 0.4904, -0.4157, 0.2778, -0.0975]]
    @Q50 = Matrix[[16,11,10,16,24,40,51,61],
                  [12,12,14,19,26,58,60,55],
                  [14,13,16,24,40,57,69,56],
                  [14,17,22,29,51,87,80,62],
                  [18,22,37,56,68,109,103,77],
                  [24,35,55,64,81,104,113,92],
                  [49,64,78,87,103,121,120,101],
                  [72,92,95,98,112,100,103,99]]
  end

  def chunks
    counter = 0
    (12..409_612).each_slice(5120) do |i|
      box = Matrix[]
      i.each do |a|
        column = [@mpixels[a].to_i - 128,
                  @mpixels[a+640].to_i - 128,
                  @mpixels[a+1280].to_i - 128,
                  @mpixels[a+1920].to_i - 128,
                  @mpixels[a+2560].to_i - 128,
                  @mpixels[a+3200].to_i - 128,
                  @mpixels[a+3840].to_i - 128,
                  @mpixels[a+4480].to_i - 128]
        mcolumn = Matrix[column]
        box = if counter.zero?
                Matrix.vstack(mcolumn)
              else
                box.vstack(mcolumn)
              end
        if counter == 7
          dct = @T*box*@T.transpose
          quantized  = [[],[],[],[],[],[],[],[]] 
          quantized_sorted  = [[],[],[],[],[],[],[],[]] 
          dct.each_with_index {|b,i,j| quantized[i][j] = (b/@Q50[i,j]).round}
          row_sorted= 0
          column_sorted=0
          idx = 0
          idx_row = 0
          row = 0
          column = 0
          loop do
            loop do
              quantized_sorted[row_sorted][column_sorted] = quantized[row][column]
              if column_sorted == 7
                row_sorted += 1
                column_sorted = 0
              else
                column_sorted += 1
              end
              # if idx == 7 && column.zero?
              #   row += 1
              # end
              break if column == idx_row
              row += 1
              column -= 1
            end
            break if (row == 7 && column == 7)
            if idx == 7
              idx_row += 1
              row = idx_row
            end
            if idx < 7
              idx += 1
              row = 0
            end
            column = idx
          end
          binding.pry

          idx = 7
          for i in ((a-8)..a)
            @dctpixels[i] = quantized_sorted[idx][0]
            @dctpixels[i + 640] = quantized_sorted[idx][1]
            @dctpixels[i + 1280] = quantized_sorted[idx][2]
            @dctpixels[i + 1920] = quantized_sorted[idx][3]
            @dctpixels[i + 2560] = quantized_sorted[idx][4]
            @dctpixels[i + 3200] = quantized_sorted[idx][5]
            @dctpixels[i + 3840] = quantized_sorted[idx][6]
            @dctpixels[i + 4480] = quantized_sorted[idx][7]
            idx -= idx
          end
          box = Matrix[]
        end
        if counter < 7
          counter += 1
        else
          counter = 0
        end
      end
    end
  end
  def write_pgm
    f = File.new('steph2.pgm', 'w')
    f.write("P2\n")
    f.write("640 640 \n")
    f.write("256\n")
    f.close
    IO.write("steph2.pgm", @dctpixels.join("\n"))
  end
end

describe MyJPEG, '.sabe o tamanho do arquivo e ' do
  let(:imagem) { MyJPEG.new('steph.pgm') }
  it 'Carrega o arquivo pgm' do
    expect(imagem.file_size.to_i).to eq(640)
  end
  it 'Separa em chunks de 8x8' do
    imagem.chunks
    imagem.write_pgm
  end
end

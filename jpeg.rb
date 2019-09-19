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
          quantized = [[],[],[],[],[],[],[],[]] 
          dct.each_with_index {|b,i,j| quantized[i][j] = (b/@Q50[i,j]).round}
          idx = 7
          0..7.each do |idx|
            row = 0
            column = idx
            loop do
              @dctpixels[] = quantized[row][column]
              break if column.zero?
              row += row
              column -= column
            end
          end
          a..(a-8).each do
            @dctpixels[a] = dct[idx,0]
            @dctpixels[a+640] = dct[idx,1]
            @dctpixels[a+1280] = dct[idx,2]
            @dctpixels[a+1920] = dct[idx,3]
            @dctpixels[a+2560] = dct[idx,4]
            @dctpixels[a+3200] = dct[idx,5]
            @dctpixels[a+3840] = dct[idx,6]
            @dctpixels[a+4480] = dct[idx,7]
            idx -= idx
          end

          box = Matrix[]
        end
        if counter < 7
          counter = counter + 1
        else
          counter = 0
        end
      end
    end
  end
end

describe MyJPEG, '.sabe o tamanho do arquivo e ' do
  let(:imagem) { MyJPEG.new('steph.pgm') }
  it 'Carrega o arquivo pgm' do
    expect(imagem.file_size.to_i).to eq(640)
  end
  it 'Separa em chunks de 8x8' do
    imagem.chunks
  end
end

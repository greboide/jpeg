require 'rspec/autorun'
require 'matrix'
require 'pry'

class MyJPEG
  # @param mpixels [Matrix]
  attr_accessor :mpixels, :file_size, :first_pixel, :file_data
  attr_reader :T, :Q50, :Q90
  def initialize(file)
    @file_data = File.read(file).split
    @mpixels = @file_data.dup
    @dctpixels_quantized = []
    @dctpixels_quantized_sorted = []
    @idctpixels = []
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
    @Q90 = Matrix[[3,2,2,3,5,8,10,12],
                  [2,2,3,4,5,12,12,11],
                  [3,3,3,5,8,11,14,11],
                  [3,3,4,6,10,17,16,12],
                  [4,4,7,11,14,22,21,15],
                  [5,7,11,13,16,12,23,18],
                  [10,13,16,17,21,24,24,21],
                  [14,18,19,20,22,20,20,20]]
  end

  def encode
    (12..409_612).each_slice(5120) do |i|
      counter = 0
      box = Matrix[]
      (i.first..(i.first+640)).each do |a|
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
          dct.each_with_index {|b,i,j| quantized[i][j] = (b/@Q90[i,j]).round}
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

          idx = 0
          for i in ((a-7)..a)
            @dctpixels_quantized_sorted[i] = quantized_sorted[idx][0]
            @dctpixels_quantized_sorted[i + 640] = quantized_sorted[idx][1]
            @dctpixels_quantized_sorted[i + 1280] = quantized_sorted[idx][2]
            @dctpixels_quantized_sorted[i + 1920] = quantized_sorted[idx][3]
            @dctpixels_quantized_sorted[i + 2560] = quantized_sorted[idx][4]
            @dctpixels_quantized_sorted[i + 3200] = quantized_sorted[idx][5]
            @dctpixels_quantized_sorted[i + 3840] = quantized_sorted[idx][6]
            @dctpixels_quantized_sorted[i + 4480] = quantized_sorted[idx][7]
            @dctpixels_quantized[i] = quantized[idx][0]
            @dctpixels_quantized[i + 640] = quantized[idx][1]
            @dctpixels_quantized[i + 1280] = quantized[idx][2]
            @dctpixels_quantized[i + 1920] = quantized[idx][3]
            @dctpixels_quantized[i + 2560] = quantized[idx][4]
            @dctpixels_quantized[i + 3200] = quantized[idx][5]
            @dctpixels_quantized[i + 3840] = quantized[idx][6]
            @dctpixels_quantized[i + 4480] = quantized[idx][7]
            idx += 1
          end
          if @dctpixels_quantized[19] != 0
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
  def decode
    counter = 0
    (12..409_612).each_slice(5120) do |i|
      box = Matrix[]
      i.each do |a|
        column = [@dctpixels_quantized[a].to_i,
                  @dctpixels_quantized[a+640].to_i,
                  @dctpixels_quantized[a+1280].to_i,
                  @dctpixels_quantized[a+1920].to_i,
                  @dctpixels_quantized[a+2560].to_i,
                  @dctpixels_quantized[a+3200].to_i,
                  @dctpixels_quantized[a+3840].to_i,
                  @dctpixels_quantized[a+4480].to_i]
        mcolumn = Matrix[column]
        box = if counter.zero?
                Matrix.vstack(mcolumn)
              else
                box.vstack(mcolumn)
              end
        if counter == 7
          reconstructed  = [[],[],[],[],[],[],[],[]]
          n  = [[],[],[],[],[],[],[],[]]
          box.each_with_index {|b,i,j| reconstructed[i][j] = b*@Q90[i,j]}
          rec = Matrix[reconstructed[0]]
          reconstructed.each_with_index { |b,i| rec = rec.vstack(Matrix[b]) if i != 0 }
          idct = @T.transpose*rec*@T
          idct.each_with_index{ |b,i,j| n[i][j] = b.round + 128 }
          idx = 0
          for i in ((a-8)..a)
            @idctpixels[i] = n[idx][0]
            @idctpixels[i + 640] = n[idx][1]
            @idctpixels[i + 1280] = n[idx][2]
            @idctpixels[i + 1920] = n[idx][3]
            @idctpixels[i + 2560] = n[idx][4]
            @idctpixels[i + 3200] = n[idx][5]
            @idctpixels[i + 3840] = n[idx][6]
            @idctpixels[i + 4480] = n[idx][7]
            idx += idx
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
  def write_decoded_pgm
    @idctpixels[9]= "P2"
    @idctpixels[10] = "640 640"
    @idctpixels[11] = "256"
    IO.write("steph2.pgm", @idctpixels[9..409_612].join("\n"))
  end
end

describe MyJPEG, '.sabe o tamanho do arquivo e ' do
  let(:imagem) { MyJPEG.new('steph.pgm') }
  it 'Carrega o arquivo pgm' do
    expect(imagem.file_size.to_i).to eq(640)
  end
  it 'Encodifica e decodifica a imagem' do
    imagem.encode
    imagem.decode
    imagem.write_decoded_pgm
  end
end

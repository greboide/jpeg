require 'rspec/autorun'
require 'matrix'
require 'pry'

class MyJPEG
  # @param mpixels [Matrix]
  attr_accessor :mpixels, :file_size, :first_pixel, :file_data
  attr_reader :T, :Q50, :Q90
  def initialize(file)
    @file_name = 'output.pgm'
    @file_data = File.read(file).split
    @mpixels = @file_data.dup
    @dctpixels_quantized = []
    @dctpixels_quantized_sorted = []
    @dctpixels = []
    @idctpixels = []
    @file_size = @file_data[10].to_i
    @first_pixel = 12
    @last_pixel = @file_size**2 + @first_pixel
    # @T = Matrix[[0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536, 0.3536],
    #             [0.4904, 0.4157, 0.2778, 0.0975, -0.0975, -0.2778, -0.4157, -0.4904],
    #             [0.4619, 0.1913, -0.1913, -0.4619, -0.4619, -0.1913, 0.1913, 0.4619],
    #             [0.4157, -0.0975, -0.4904, -0.2778, 0.2778, 0.4904, 0.0975, -0.4157],
    #             [0.3536, -0.3536, -0.3536, 0.3536, 0.3536, -0.3536, -0.3536, 0.3536],
    #             [0.2778, 0.4904, 0.0975, 0.4157, -0.4157, -0.0975, -0.4904, -0.2778],
    #             [0.1913, -0.4619, 0.4619, -0.1913, -0.1913, 0.4619, -0.4619, 0.1913],
    #             [0.0975, -0.2778, 0.4157, -0.4904, 0.4904, -0.4157, 0.2778, -0.0975]]
    @T= Matrix.build(8,8) { |i,j| if i == 0
                                   1.0/(Math.sqrt 8)
                                 else
                                   Math.sqrt(2.0/8)*Math.cos((2*j + 1)*i*Math::PI/16)
                                 end}
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
    @O = Matrix[[154,123,123,123,123,123,123,136],
                [192,180,136,154,154,154,136,110],
                [254,198,154,154,180,154,123,123],
                [239,180,136,180,180,166,123,123],
                [180,154,136,167,166,149,136,136],
                [128,136,123,136,154,180,198,154],
                [123,105,110,149,136,136,180,166],
                [110,136,123,123,123,136,154,136]]
  end
  def return_box_for_decoding(a)
    Matrix[[@dctpixels[a].to_i,
            @dctpixels[a+@file_size].to_i,
            @dctpixels[a+2*@file_size].to_i,
            @dctpixels[a+3*@file_size].to_i,
            @dctpixels[a+4*@file_size].to_i,
            @dctpixels[a+5*@file_size].to_i,
            @dctpixels[a+6*@file_size].to_i,
            @dctpixels[a+7*@file_size].to_i],
           [@dctpixels[a+1].to_i,
            @dctpixels[a+1+@file_size].to_i,
            @dctpixels[a+1+2*@file_size].to_i,
            @dctpixels[a+1+3*@file_size].to_i,
            @dctpixels[a+1+4*@file_size].to_i,
            @dctpixels[a+1+5*@file_size].to_i,
            @dctpixels[a+1+6*@file_size].to_i,
            @dctpixels[a+1+7*@file_size].to_i],
           [@dctpixels[a+2].to_i,
            @dctpixels[a+2+@file_size].to_i,
            @dctpixels[a+2+2*@file_size].to_i,
            @dctpixels[a+2+3*@file_size].to_i,
            @dctpixels[a+2+4*@file_size].to_i,
            @dctpixels[a+2+5*@file_size].to_i,
            @dctpixels[a+2+6*@file_size].to_i,
            @dctpixels[a+2+7*@file_size].to_i],
           [@dctpixels[a+3].to_i,
            @dctpixels[a+3+@file_size].to_i,
            @dctpixels[a+3+2*@file_size].to_i,
            @dctpixels[a+3+3*@file_size].to_i,
            @dctpixels[a+3+4*@file_size].to_i,
            @dctpixels[a+3+5*@file_size].to_i,
            @dctpixels[a+3+6*@file_size].to_i,
            @dctpixels[a+3+7*@file_size].to_i],
           [@dctpixels[a+4].to_i,
            @dctpixels[a+4+@file_size].to_i,
            @dctpixels[a+4+2*@file_size].to_i,
            @dctpixels[a+4+3*@file_size].to_i,
            @dctpixels[a+4+4*@file_size].to_i,
            @dctpixels[a+4+5*@file_size].to_i,
            @dctpixels[a+4+6*@file_size].to_i,
            @dctpixels[a+4+7*@file_size].to_i],
           [@dctpixels[a+5].to_i,
            @dctpixels[a+5+@file_size].to_i,
            @dctpixels[a+5+2*@file_size].to_i,
            @dctpixels[a+5+3*@file_size].to_i,
            @dctpixels[a+5+4*@file_size].to_i,
            @dctpixels[a+5+5*@file_size].to_i,
            @dctpixels[a+5+6*@file_size].to_i,
            @dctpixels[a+5+7*@file_size].to_i],
           [@dctpixels[a+6].to_i,
            @dctpixels[a+6+@file_size].to_i,
            @dctpixels[a+6+2*@file_size].to_i,
            @dctpixels[a+6+3*@file_size].to_i,
            @dctpixels[a+6+4*@file_size].to_i,
            @dctpixels[a+6+5*@file_size].to_i,
            @dctpixels[a+6+6*@file_size].to_i,
            @dctpixels[a+6+7*@file_size].to_i],
           [@dctpixels[a+7].to_i,
            @dctpixels[a+7+@file_size].to_i,
            @dctpixels[a+7+2*@file_size].to_i,
            @dctpixels[a+7+3*@file_size].to_i,
            @dctpixels[a+7+4*@file_size].to_i,
            @dctpixels[a+7+5*@file_size].to_i,
            @dctpixels[a+7+6*@file_size].to_i,
            @dctpixels[a+7+7*@file_size].to_i]
          ]
  end
  def return_box_for_encoding(a)
    Matrix[[@mpixels[a].to_i - 128,
            @mpixels[a+@file_size].to_i - 128,
            @mpixels[a+2*@file_size].to_i - 128,
            @mpixels[a+3*@file_size].to_i - 128,
            @mpixels[a+4*@file_size].to_i - 128,
            @mpixels[a+5*@file_size].to_i - 128,
            @mpixels[a+6*@file_size].to_i - 128,
            @mpixels[a+7*@file_size].to_i - 128],
           [@mpixels[a+1].to_i - 128,
            @mpixels[a+1+@file_size].to_i - 128,
            @mpixels[a+1+2*@file_size].to_i - 128,
            @mpixels[a+1+3*@file_size].to_i - 128,
            @mpixels[a+1+4*@file_size].to_i - 128,
            @mpixels[a+1+5*@file_size].to_i - 128,
            @mpixels[a+1+6*@file_size].to_i - 128,
            @mpixels[a+1+7*@file_size].to_i - 128],
           [@mpixels[a+2].to_i - 128,
            @mpixels[a+2+@file_size].to_i - 128,
            @mpixels[a+2+2*@file_size].to_i - 128,
            @mpixels[a+2+3*@file_size].to_i - 128,
            @mpixels[a+2+4*@file_size].to_i - 128,
            @mpixels[a+2+5*@file_size].to_i - 128,
            @mpixels[a+2+6*@file_size].to_i - 128,
            @mpixels[a+2+7*@file_size].to_i - 128],
           [@mpixels[a+3].to_i - 128,
            @mpixels[a+3+@file_size].to_i - 128,
            @mpixels[a+3+2*@file_size].to_i - 128,
            @mpixels[a+3+3*@file_size].to_i - 128,
            @mpixels[a+3+4*@file_size].to_i - 128,
            @mpixels[a+3+5*@file_size].to_i - 128,
            @mpixels[a+3+6*@file_size].to_i - 128,
            @mpixels[a+3+7*@file_size].to_i - 128],
           [@mpixels[a+4].to_i - 128,
            @mpixels[a+4+@file_size].to_i - 128,
            @mpixels[a+4+2*@file_size].to_i - 128,
            @mpixels[a+4+3*@file_size].to_i - 128,
            @mpixels[a+4+4*@file_size].to_i - 128,
            @mpixels[a+4+5*@file_size].to_i - 128,
            @mpixels[a+4+6*@file_size].to_i - 128,
            @mpixels[a+4+7*@file_size].to_i - 128],
           [@mpixels[a+5].to_i - 128,
            @mpixels[a+5+@file_size].to_i - 128,
            @mpixels[a+5+2*@file_size].to_i - 128,
            @mpixels[a+5+3*@file_size].to_i - 128,
            @mpixels[a+5+4*@file_size].to_i - 128,
            @mpixels[a+5+5*@file_size].to_i - 128,
            @mpixels[a+5+6*@file_size].to_i - 128,
            @mpixels[a+5+7*@file_size].to_i - 128],
           [@mpixels[a+6].to_i - 128,
            @mpixels[a+6+@file_size].to_i - 128,
            @mpixels[a+6+2*@file_size].to_i - 128,
            @mpixels[a+6+3*@file_size].to_i - 128,
            @mpixels[a+6+4*@file_size].to_i - 128,
            @mpixels[a+6+5*@file_size].to_i - 128,
            @mpixels[a+6+6*@file_size].to_i - 128,
            @mpixels[a+6+7*@file_size].to_i - 128],
           [@mpixels[a+7].to_i - 128,
            @mpixels[a+7+@file_size].to_i - 128,
            @mpixels[a+7+2*@file_size].to_i - 128,
            @mpixels[a+7+3*@file_size].to_i - 128,
            @mpixels[a+7+4*@file_size].to_i - 128,
            @mpixels[a+7+5*@file_size].to_i - 128,
            @mpixels[a+7+6*@file_size].to_i - 128,
            @mpixels[a+7+7*@file_size].to_i - 128]
          ]
  end
  def write_dct(a,dct)
    (0..7).each do |idx|
      @dctpixels[a + idx] = dct[idx,0].round
      @dctpixels[a + idx + @file_size] = dct[idx,1].round
      @dctpixels[a + idx + 2*@file_size] = dct[idx,2].round
      @dctpixels[a + idx + 3*@file_size] = dct[idx,3].round
      @dctpixels[a + idx + 4*@file_size] = dct[idx,4].round
      @dctpixels[a + idx + 5*@file_size] = dct[idx,5].round
      @dctpixels[a + idx + 6*@file_size] = dct[idx,6].round
      @dctpixels[a + idx + 7*@file_size] = dct[idx,7].round
    end
  end
  def write_dct_quantized(a,dct)
    (0..7).each do |idx|
      @dctpixels[a + idx] = dct[idx][0]
      @dctpixels[a + idx + @file_size] = dct[idx][1]
      @dctpixels[a + idx + 2*@file_size] = dct[idx][2]
      @dctpixels[a + idx + 3*@file_size] = dct[idx][3]
      @dctpixels[a + idx + 4*@file_size] = dct[idx][4]
      @dctpixels[a + idx + 5*@file_size] = dct[idx][5]
      @dctpixels[a + idx + 6*@file_size] = dct[idx][6]
      @dctpixels[a + idx + 7*@file_size] = dct[idx][7]
    end
  end
  def write_idct(a,n)
    (0..7).each do |idx|
      @idctpixels[a + idx] = n[idx][0]
      @idctpixels[a + idx + @file_size] = n[idx][1]
      @idctpixels[a + idx + 2*@file_size] = n[idx][2]
      @idctpixels[a + idx + 3*@file_size] = n[idx][3]
      @idctpixels[a + idx + 4*@file_size] = n[idx][4]
      @idctpixels[a + idx + 5*@file_size] = n[idx][5]
      @idctpixels[a + idx + 6*@file_size] = n[idx][6]
      @idctpixels[a + idx + 7*@file_size] = n[idx][7]
    end
  end
  def zigzag(quantized)
    quantized_sorted  = [[],[],[],[],[],[],[],[]]
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
    return quantized_sorted
  end
  def encode
    (@first_pixel..@last_pixel-1).each_slice(8*@file_size) do |slice|
      slice[0..@file_size-1].each_slice(8) do |pixel|
        box = return_box_for_encoding(pixel.first)
        dct = @T*box*@T.transpose
        quantized  = [[],[],[],[],[],[],[],[]]
        dct.each_with_index {|b,i,j| quantized[i][j] = (b/@Q90[i,j]).round}
        write_dct_quantized(pixel.first,quantized)
      end
    end
  end
  def decode
    (@first_pixel..@last_pixel-1).each_slice(8*@file_size)do |slice|
      slice[0..@file_size-1].each_slice(8) do |pixel|
        box = return_box_for_decoding(pixel.first)
        reconstructed = [[],[],[],[],[],[],[],[]]
        n  = [[],[],[],[],[],[],[],[]]
        box.each_with_index { |b, c, d| reconstructed[c][d] = b * @Q90[c, d] }
        rec = Matrix[reconstructed[0]]
        reconstructed.each_with_index { |b,i| rec = rec.vstack(Matrix[b]) if i != 0 }
        idct = @T.transpose*rec*@T
        idct.each_with_index{ |b,i,j| n[i][j] = b.round + 128 }
        write_idct(pixel.first,n)
      end
    end
  end
  def write_decoded_pgm
    @idctpixels[9]= "P2"
    @idctpixels[10] = @file_size.to_s + ' ' + @file_size.to_s
    @idctpixels[11] = "255"
    IO.write(@file_name, @idctpixels[9..@last_pixel].join("\n"))
  end
end

describe MyJPEG, '.sabe o tamanho do arquivo e ' do
  let(:imagem) { MyJPEG.new('steph.pgm') }
  it 'Encodifica e decodifica a imagem' do
    imagem.encode
    imagem.decode
    imagem.write_decoded_pgm
  end
end

class Opencv < Formula
    desc "Open source computer vision library"
    homepage "https://opencv.org/"
    url "https://github.com/opencv/opencv/archive/4.0.0.tar.gz"
    sha256 "3787b3cc7b21bba1441819cb00c636911a846c0392ddf6211d398040a1e4886c"
  
    depends_on "cmake" => :build
    depends_on "pkg-config" => :build
    depends_on "eigen"
    depends_on "ffmpeg"
    depends_on "jpeg"
    depends_on "libpng"
    depends_on "libtiff"
    depends_on "numpy"
    depends_on "openexr"
    depends_on "python"
    depends_on "python@2"
    depends_on "tbb"
    depends_on "gcc"
  
    resource "contrib" do
      url "https://github.com/opencv/opencv_contrib/archive/4.0.0.tar.gz"
      sha256 "4fb0681414df4baedce6e3f4a01318d6f4fcde6ee14854d761fd4e397a397763"
    end
  
    needs :cxx11
  
    def install
      ENV.cxx11
      ENV.prepend_path "PATH", Formula["python@2"].opt_libexec/"bin"
  
      resource("contrib").stage buildpath/"opencv_contrib"
  
      # Reset PYTHONPATH, workaround for https://github.com/Homebrew/homebrew-science/pull/4885
      ENV.delete("PYTHONPATH")
  
      py2_prefix = `python2-config --prefix`.chomp
      py2_lib = "#{py2_prefix}/lib"
  
      py3_config = `python3-config --configdir`.chomp
      py3_include = `python3 -c "import distutils.sysconfig as s; print(s.get_python_inc())"`.chomp
      py3_version = Language::Python.major_minor_version "python3"
  
      args = std_cmake_args + %W[
        -DCMAKE_OSX_DEPLOYMENT_TARGET=
        -DBUILD_JASPER=OFF
        -DBUILD_JPEG=ON
        -DBUILD_OPENEXR=OFF
        -DBUILD_PERF_TESTS=OFF
        -DBUILD_PNG=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_TIFF=OFF
        -DBUILD_ZLIB=OFF
        -DBUILD_opencv_hdf=OFF
        -DBUILD_opencv_java=OFF
        -DBUILD_opencv_text=OFF
        -DOPENCV_ENABLE_NONFREE=ON
        -DWITH_1394=OFF
        -DWITH_CUDA=OFF
        -DWITH_EIGEN=ON
        -DWITH_FFMPEG=ON
        -DWITH_GPHOTO2=OFF
        -DWITH_GSTREAMER=OFF
        -DWITH_JASPER=OFF
        -DWITH_OPENEXR=ON
        -DWITH_OPENGL=OFF
        -DWITH_QT=OFF
        -DWITH_TBB=ON
        -DWITH_VTK=OFF
        -DBUILD_opencv_python2=ON
        -DBUILD_opencv_python3=ON
        -DPYTHON2_EXECUTABLE=#{which "python"}
        -DPYTHON2_LIBRARY=#{py2_lib}/libpython2.7.dylib
        -DPYTHON2_INCLUDE_DIR=#{py2_prefix}/include/python2.7
        -DPYTHON3_EXECUTABLE=#{which "python3"}
        -DPYTHON3_LIBRARY=#{py3_config}/libpython#{py3_version}.dylib
        -DPYTHON3_INCLUDE_DIR=#{py3_include}
        -DOPENCV_EXTRA_MODULES_PATH=#{buildpath}/opencv_contrib/modules
      ]
  
      if build.bottle?
        args += %w[-DENABLE_SSE41=OFF -DENABLE_SSE42=OFF -DENABLE_AVX=OFF
                   -DENABLE_AVX2=OFF]
      end

      mkdir "build" do
        system "cmake", "..", *args
        system "make -j$(sysctl -n hw.physicalcpu)"
        system "make", "install"
        system "make", "clean"
        system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", *args
        system "make -j$(sysctl -n hw.physicalcpu)"
        lib.install Dir["lib/*.a"]
        lib.install Dir["3rdparty/**/*.a"]
      end
    end
  
    test do
      (testpath/"test.cpp").write <<~EOS
        #include <opencv/cv.h>
        #include <iostream>
        int main() {
          std::cout << CV_VERSION << std::endl;
          return 0;
        }
      EOS
      system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-o", "test"
      assert_equal `./test`.strip, version.to_s
  
      ["python2.7", "python3"].each do |python|
        output = shell_output("#{python} -c 'import cv2; print(cv2.__version__)'")
        assert_equal version.to_s, output.chomp
      end
    end
  end
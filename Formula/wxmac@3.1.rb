class WxmacAT31 < Formula
  desc "Cross-platform C++ GUI toolkit (wxWidgets for macOS)"
  homepage "https://www.wxwidgets.org"
  url "https://github.com/wxWidgets/wxWidgets/releases/download/v3.1.2/wxWidgets-3.1.2.tar.bz2"
  sha256 "4cb8d23d70f9261debf7d6cfeca667fc0a7d2b6565adb8f1c484f9b674f1f27a"
  revision 1
  head "https://github.com/wxWidgets/wxWidgets.git"

  option "with-stl", "use standard C++ classes for everything"
  option "with-static", "build static libraries"

  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libtiff"

  # Fixes ld: warning: direct access in function ... to global weak symbol ...
  patch :DATA

  def install
    ENV.cxx11
    args = [
      "--prefix=#{prefix}",
      "--enable-clipboard",
      "--enable-controls",
      "--enable-dataviewctrl",
      "--enable-display",
      "--enable-dnd",
      "--enable-graphics_ctx",
      "--enable-std_string",
      "--enable-svg",
      "--enable-unicode",
      "--enable-webkit",
      "--enable-optimise",
      "--with-cxx=14",
      "--with-expat",
      "--with-libjpeg",
      "--with-libpng",
      "--with-libtiff",
      "--with-opengl",
      "--with-osx_cocoa",
      "--with-zlib",
      "--disable-precomp-headers",
      # This is the default option, but be explicit
      "--disable-monolithic",
      # Set with-macosx-version-min to avoid configure defaulting to 10.5
      "--with-macosx-version-min=#{MacOS.version}",
    ]

    args << "--enable-stl" if build.with? "stl"
    args << (build.with?("static") ? "--disable-shared" : "--enable-shared")

    system "./configure", *args
    system "make", "install"

    # wx-config should reference the public prefix, not wxmac's keg
    # this ensures that Python software trying to locate wxpython headers
    # using wx-config can find both wxmac and wxpython headers,
    # which are linked to the same place
    inreplace "#{bin}/wx-config", prefix, HOMEBREW_PREFIX
  end

  test do
    system bin/"wx-config", "--libs"
  end
end

__END__
--- a/include/wx/containr.h
+++ b/include/wx/containr.h
@@ -270,17 +270,17 @@

 protected:
 #ifndef wxHAS_NATIVE_TAB_TRAVERSAL
-    void OnNavigationKey(wxNavigationKeyEvent& event)
+    virtual void OnNavigationKey(wxNavigationKeyEvent& event)
     {
         m_container.HandleOnNavigationKey(event);
     }

-    void OnFocus(wxFocusEvent& event)
+    virtual void OnFocus(wxFocusEvent& event)
     {
         m_container.HandleOnFocus(event);
     }

-    void OnChildFocus(wxChildFocusEvent& event)
+    virtual void OnChildFocus(wxChildFocusEvent& event)
     {
         m_container.SetLastFocus(event.GetWindow());
         event.Skip();
--- a/include/wx/vector.h
+++ b/include/wx/vector.h
@@ -519,7 +519,7 @@
         // if the ctor called below throws an exception, we need to move all
         // the elements back to their original positions in m_values
         wxScopeGuard moveBack = wxMakeGuard(
-                Ops::MemmoveBackward, place, place + count, after);
+                [&]() { Ops::MemmoveBackward(place, place + count, after); });
         if ( !after )
             moveBack.Dismiss();
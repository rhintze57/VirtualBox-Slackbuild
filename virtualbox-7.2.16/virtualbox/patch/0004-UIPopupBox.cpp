diff -ur /tmp/VirtualBox-6.1.8/src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.cpp /tmp/VirtualBox-6.1.8.patched/src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.cpp

Index: src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.cpp
===================================================================
--- src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.cpp 2020-05-14 14:40:44.000000000 -0400
+++ src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.cpp 2020-06-03 10:47:51.348523624 -0400
@@ -19,6 +19,7 @@
 #include <QApplication>
 #include <QLabel>
 #include <QPainter>
+#include <QPainterPath>
 #include <QPaintEvent>
 #include <QStyle>
 #include <QVBoxLayout>


diff -ur /tmp/VirtualBox-6.1.8/src/VBox/Frontends/VirtualBox/src/widgets/UIMenuToolBar.cpp /tmp/VirtualBox-6.1.8.patched/src/VBox/Frontends/VirtualBox/src/widgets/UIMenuToolBar.cpp

Index: src/VBox/Frontends/VirtualBox/src/widgets/UIMenuToolBar.cpp
===================================================================
--- src/VBox/Frontends/VirtualBox/src/widgets/UIMenuToolBar.cpp 2020-05-14 14:40:44.000000000 -0400
+++ src/VBox/Frontends/VirtualBox/src/widgets/UIMenuToolBar.cpp 2020-06-03 10:52:50.125585673 -0400
@@ -19,6 +19,7 @@
 #include <QApplication>
 #include <QHBoxLayout>
 #include <QPainter>
+#include <QPainterPath>
 #include <QStyle>
 #include <QToolButton>

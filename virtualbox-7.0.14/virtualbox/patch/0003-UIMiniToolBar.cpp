diff -ur /tmp/VirtualBox-6.1.8/src/VBox/Frontends/VirtualBox/src/widgets/UIMiniToolBar.cpp /tmp/VirtualBox-6.1.8.patched/src/VBox/Frontends/VirtualBox/src/widgets/UIMiniToolBar.cpp

Index: src/VBox/Frontends/VirtualBox/src/widgets/UIMiniToolBar.cpp
===================================================================
--- src/VBox/Frontends/VirtualBox/src/widgets/UIMiniToolBar.cpp 2020-05-14 14:40:44.000000000 -0400
+++ src/VBox/Frontends/VirtualBox/src/widgets/UIMiniToolBar.cpp 2020-06-03 10:51:38.560369848 -0400
@@ -21,6 +21,7 @@
 #include <QMenu>
 #include <QMoveEvent>
 #include <QPainter>
+#include <QPainterPath>
 #include <QStateMachine>
 #include <QStyle>
 #include <QTimer>


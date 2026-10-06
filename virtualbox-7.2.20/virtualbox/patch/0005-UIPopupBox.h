diff -ur /tmp/VirtualBox-6.1.8/src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.h /tmp/VirtualBox-6.1.8.patched/src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.h

Index: src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.h
===================================================================
--- src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.h 2020-05-14 14:40:44.000000000 -0400
+++ src/VBox/Frontends/VirtualBox/src/widgets/UIPopupBox.h 2020-06-03 10:49:01.201695063 -0400
@@ -24,6 +24,7 @@
 /* Qt includes: */
 #include <QIcon>
 #include <QWidget>
+#include <QPainterPath>
 
 /* GUI includes: */
 #include "UILibraryDefs.h"


diff -ur /tmp/VirtualBox-6.1.8/src/VBox/Frontends/VirtualBox/src/globals/UIImageTools.cpp /tmp/VirtualBox-6.1.8.patched/src/VBox/Frontends/VirtualBox/src/globals/UIImageTools.cpp

Index: src/VBox/Frontends/VirtualBox/src/globals/UIImageTools.cpp
===================================================================
--- a/src/VBox/Frontends/VirtualBox/src/globals/UIImageTools.cpp 2020-05-14 14:40:35.000000000 -0400
+++ b/src/VBox/Frontends/VirtualBox/src/globals/UIImageTools.cpp 2020-06-03 10:46:06.750776100 -0400
@@ -17,6 +17,7 @@
 
 /* Qt includes: */
 #include <QPainter>
+#include <QPainterPath>
 
 /* GUI include */
 #include "UIImageTools.h"


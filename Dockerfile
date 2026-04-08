# ============================================
# Stage 1: بناء تطبيق React (Frontend)
# ============================================
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# نسخ ملفات الاعتماديات الخاصة بـ frontend
COPY frontend/package*.json ./
RUN npm install

# نسخ كود frontend بالكامل
COPY frontend/ ./

# حل مشكلة CustomEvent في Vite
ENV NODE_OPTIONS="--no-experimental-fetch"
ENV CI=false
ENV DISABLE_ESLINT_PLUGIN=true

# بناء تطبيق React
RUN npm run build

# ============================================
# Stage 2: تجهيز Backend (Node.js/Express)
# ============================================
FROM node:18-alpine AS backend-builder

WORKDIR /app/backend

# نسخ ملفات الاعتماديات الخاصة بـ backend
COPY backend/package*.json ./
RUN npm install

# نسخ كود backend بالكامل
COPY backend/ ./

# ============================================
# Stage 3: الصورة النهائية
# ============================================
FROM node:18-alpine

WORKDIR /app

# نسخ backend من المرحلة السابقة
COPY --from=backend-builder /app/backend ./backend

# نسخ ملفات frontend المبنية (HTML, CSS, JS)
COPY --from=frontend-builder /app/frontend/build ./frontend/build

# تثبيت فقط dependencies الإنتاجية للـ backend
WORKDIR /app/backend
RUN npm install --omit=dev

# فتح المنفذ
EXPOSE 3000

# تشغيل الخادم
CMD ["npm", "start"]

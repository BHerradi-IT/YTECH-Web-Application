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
# Stage 2: الصورة النهائية (Backend + Frontend)
# ============================================
FROM node:18-alpine

WORKDIR /app

# تثبيت PostgreSQL client (اختياري)
RUN apk add --no-cache postgresql-client

# نسخ ملفات الاعتماديات الخاصة بـ backend
COPY backend/package*.json ./
RUN npm install --omit=dev

# نسخ كود backend بالكامل
COPY backend/ ./

# نسخ ملفات frontend المبنية من المرحلة السابقة
COPY --from=frontend-builder /app/frontend/build ./frontend/build

# إنشاء مجلد للبيانات (إذا لزم الأمر)
RUN mkdir -p /app/data /app/logs

# متغيرات البيئة الافتراضية
ENV NODE_ENV=production
ENV PORT=5001
ENV HOST=0.0.0.0

# فتح المنفذ
EXPOSE 5001

# تشغيل الخادم
CMD ["node", "server.js"]

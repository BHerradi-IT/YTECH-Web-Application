
# Stage 1: بناء تطبيق React
FROM node:18-alpine AS builder
WORKDIR /app

# نسخ ملفات الاعتماديات
COPY frontend/package*.json ./
RUN npm install

# نسخ كل كود المصدر
COPY frontend/ ./

# مهم جداً: منع أخطاء ESLint من إيقاف البناء
ENV CI=false
ENV DISABLE_ESLINT_PLUGIN=true

# بناء التطبيق
RUN npm run build

# Stage 2: التشغيل باستخدام Nginx
FROM nginx:alpine
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

FROM node:18-alpine

WORKDIR /app

# Copy node_modules first (if it exists locally, it will be used)
COPY package.json ./
RUN npm install --no-optional --prefer-offline 2>&1 || echo "npm install failed, trying offline..."
RUN npm install --no-optional 2>&1 || true

COPY . .

EXPOSE 3000

CMD ["npm", "run", "dev"]

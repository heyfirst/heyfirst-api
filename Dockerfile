# base node image
FROM node:19-bullseye-slim AS base

# set for base and all that inherit from it
# Install openssl for Prisma
RUN apt-get update && apt-get install -y openssl ca-certificates iptables
RUN npm install --location=global pnpm

# [deps] Install all node_modules, including dev dependencies
FROM base AS deps

RUN mkdir /app
WORKDIR /app

ADD package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# [production-deps] Setup production node_modules
FROM base AS production-deps

RUN mkdir /app
WORKDIR /app

COPY --from=deps /app/node_modules /app/node_modules
ADD package.json pnpm-lock.yaml ./
RUN pnpm prune --prod

# [build]  Build the app
FROM base AS build

RUN mkdir /app
WORKDIR /app

COPY --from=deps /app/node_modules /app/node_modules

ADD . .
RUN pnpx prisma generate
RUN pnpm run build

# [main] Finally, build the production image with minimal footprint
FROM base

ENV NODE_ENV=production

RUN mkdir /app
WORKDIR /app

COPY --from=production-deps /app/node_modules /app/node_modules
COPY --from=build /app/node_modules/.prisma /app/node_modules/.prisma
COPY --from=build /app/dist /app/dist

ADD . .

ENV NODE_ENV production

CMD ["./script/docker-entrypoint.sh"]

EXPOSE 8080

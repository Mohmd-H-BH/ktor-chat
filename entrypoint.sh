#!/bin/sh
# Render.com injects $PORT; default to 10000 if not set
PORT=${PORT:-10000}

# Write nginx config with the correct port
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen ${PORT};
    root /usr/share/nginx/html;
    index index.html;

    # Support client-side routing (Compose Navigation)
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Cache wasm/js aggressively
    location ~* \.(wasm|js|mjs)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
}
EOF

exec nginx -g 'daemon off;'

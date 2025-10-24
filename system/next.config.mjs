// next.config.mjs
/** @type {import('next').NextConfig} */
const nextConfig = {
    experimental: {
        serverComponentsExternalPackages: ['ffmpeg-static', 'ffprobe-static'],
    },
    outputFileTracingIncludes: {
        // include the binaries for the watermark API route
        'app/api/watermark/route': [
            './node_modules/ffmpeg-static/**',
            './node_modules/ffprobe-static/bin/**',
        ],
    },
};

export default nextConfig;
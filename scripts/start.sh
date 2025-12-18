#!/bin/bash

echo "Starting TestGen services..."

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose is not installed"
    exit 1
fi

# Build and start services
docker-compose up -d --build

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check service health
echo ""
echo "Checking service health..."
echo ""

# Check Auth Service
if curl -s http://localhost/api/auth/health > /dev/null 2>&1; then
    echo "✓ Auth Service is running"
else
    echo "✗ Auth Service is not responding"
fi

# Check Generation Service
if curl -s http://localhost/api/documents/health > /dev/null 2>&1; then
    echo "✓ Generation Service is running"
else
    echo "✗ Generation Service is not responding"
fi

# Check Testing Service
if curl -s http://localhost/api/tests/health > /dev/null 2>&1; then
    echo "✓ Testing Service is running"
else
    echo "✗ Testing Service is not responding"
fi

echo ""
echo "TestGen is ready!"
echo ""
echo "Access the application at: http://localhost"
echo ""
echo "Default admin credentials:"
echo "  Email: admin@testgen.com"
echo "  Password: admin123"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"

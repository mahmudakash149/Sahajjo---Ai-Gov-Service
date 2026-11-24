const {
  S3Client,
  HeadBucketCommand,
  CreateBucketCommand,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const config = require('../config');

const s3Client = new S3Client({
  endpoint: config.s3.endpoint,
  region: config.s3.region,
  forcePathStyle: config.s3.forcePathStyle,
  requestChecksumCalculation: 'WHEN_REQUIRED',
  responseChecksumValidation: 'WHEN_REQUIRED',
  credentials: {
    accessKeyId: config.s3.accessKey,
    secretAccessKey: config.s3.secretKey,
  },
});

const BUCKET = config.s3.bucket;
let bucketEnsured = false;

async function ensureBucket() {
  if (bucketEnsured) return;
  try {
    await s3Client.send(new HeadBucketCommand({ Bucket: BUCKET }));
    bucketEnsured = true;
  } catch (err) {
    const status = err.$metadata && err.$metadata.httpStatusCode;
    if (status === 404 || err.name === 'NotFound' || err.name === 'NoSuchBucket') {
      await s3Client.send(new CreateBucketCommand({ Bucket: BUCKET }));
      bucketEnsured = true;
    } else {
      throw err;
    }
  }
}

async function createPresignedUploadUrl(key, contentType, expiresIn = 300) {
  await ensureBucket();
  const command = new PutObjectCommand({
    Bucket: BUCKET,
    Key: key,
    ContentType: contentType,
  });
  return getSignedUrl(s3Client, command, { expiresIn });
}

async function createPresignedDownloadUrl(key, expiresIn = 300) {
  await ensureBucket();
  const command = new GetObjectCommand({
    Bucket: BUCKET,
    Key: key,
  });
  return getSignedUrl(s3Client, command, { expiresIn });
}

async function uploadBuffer(key, buffer, contentType) {
  await ensureBucket();
  await s3Client.send(
    new PutObjectCommand({
      Bucket: BUCKET,
      Key: key,
      Body: buffer,
      ContentType: contentType,
    })
  );
  return { bucket: BUCKET, key };
}

async function getObjectBuffer(key) {
  const response = await s3Client.send(
    new GetObjectCommand({
      Bucket: BUCKET,
      Key: key,
    })
  );
  const chunks = [];
  for await (const chunk of response.Body) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

async function deleteObject(key) {
  try {
    await s3Client.send(
      new DeleteObjectCommand({
        Bucket: BUCKET,
        Key: key,
      })
    );
  } catch (err) {
    console.warn('[S3 Service] Delete object warning:', err.message);
  }
}

module.exports = {
  BUCKET,
  s3Client,
  ensureBucket,
  createPresignedUploadUrl,
  createPresignedDownloadUrl,
  uploadBuffer,
  getObjectBuffer,
  deleteObject,
};

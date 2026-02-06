package com.example.secure_storage

import android.content.Context
import android.content.pm.PackageManager
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.charset.StandardCharsets
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class SecureStoragePlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var appContext: Context
  private val tag = "SecureStoragePlugin"

  private val keyStoreType = "AndroidKeyStore"
  private val aesMode = "AES/GCM/NoPadding"
  private val ivSizeBytes = 12
  private val tagSizeBits = 128

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "secure_storage")
    appContext = flutterPluginBinding.applicationContext
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "containsAlias" -> handleContainsAlias(call, result)
      "generateKey" -> handleGenerateKey(call, result)
      "deleteEntry" -> handleDeleteEntry(call, result)
      "encrypt" -> handleEncrypt(call, result)
      "decrypt" -> handleDecrypt(call, result)
      "isStrongBoxAvailable" -> handleIsStrongBoxAvailable(result)
      else -> result.notImplemented()
    }
  }

  private fun handleContainsAlias(call: MethodCall, result: Result) {
    try {
      val alias = call.argument<String>("alias")
        ?: run {
          result.error("bad_args", "Missing alias.", null)
          return
        }
      result.success(getKey(alias) != null)
    } catch (e: Exception) {
      result.error("contains_alias_failed", e.message ?: e.toString(), null)
    }
  }

  private fun handleGenerateKey(call: MethodCall, result: Result) {
    try {
      val alias = call.argument<String>("alias")
        ?: run {
          result.error("bad_args", "Missing alias.", null)
          return
        }
      val unlockedDeviceRequired = call.argument<Boolean>("unlockedDeviceRequired")
        ?: run {
          result.error("bad_args", "Missing unlockedDeviceRequired.", null)
          return
        }
      val keyStore = KeyStore.getInstance(keyStoreType)
      keyStore.load(null)
      if (keyStore.containsAlias(alias)) {
        result.success(null)
        return
      }
      val keyGenerator = KeyGenerator.getInstance(
        KeyProperties.KEY_ALGORITHM_AES,
        keyStoreType
      )
      val specBuilder = KeyGenParameterSpec.Builder(
        alias,
        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
      )
        .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
        .setKeySize(256)
        .setRandomizedEncryptionRequired(true)
        .setUnlockedDeviceRequired(unlockedDeviceRequired)
      try {
        specBuilder.setIsStrongBoxBacked(true)
      } catch (e: Exception) {
        Log.i(tag, "StrongBox not available", e)
      }
      keyGenerator.init(specBuilder.build())
      keyGenerator.generateKey()
      result.success(null)
    } catch (e: Exception) {
      result.error("generate_key_failed", e.message ?: e.toString(), null)
    }
  }

  private fun handleDeleteEntry(call: MethodCall, result: Result) {
    try {
      val alias = call.argument<String>("alias")
        ?: run {
          result.error("bad_args", "Missing alias.", null)
          return
        }
      val keyStore = KeyStore.getInstance(keyStoreType)
      keyStore.load(null)
      if (keyStore.containsAlias(alias)) {
        keyStore.deleteEntry(alias)
      }
      result.success(null)
    } catch (e: Exception) {
      result.error("delete_entry_failed", e.message ?: e.toString(), null)
    }
  }

  private fun handleEncrypt(call: MethodCall, result: Result) {
    try {
      val plaintext = call.argument<ByteArray>("plaintext")
      val aad = call.argument<String>("aad")
      val alias = call.argument<String>("alias")
      if (plaintext == null || aad == null || alias == null) {
        result.error("bad_args", "Missing plaintext, aad, or alias.", null)
        return
      }

      val key = getKey(alias)
        ?: run {
          result.error("key_not_found", "Key not found for alias.", null)
          return
        }
      val cipher = Cipher.getInstance(aesMode)
      cipher.init(Cipher.ENCRYPT_MODE, key)
      cipher.updateAAD(aad.toByteArray(StandardCharsets.UTF_8))
      val ciphertext = cipher.doFinal(plaintext)
      val nonce = cipher.iv
        ?: run {
          result.error("encrypt_failed", "Invalid nonce.", null)
          return
        }
      if (nonce.size != ivSizeBytes) {
        result.error("encrypt_failed", "Invalid nonce size.", null)
        return
      }
      result.success(mapOf("nonce" to nonce, "ciphertext" to ciphertext))
    } catch (e: Exception) {
      result.error("encrypt_failed", e.message ?: e.toString(), null)
    }
  }

  private fun handleDecrypt(call: MethodCall, result: Result) {
    try {
      val ciphertext = call.argument<ByteArray>("ciphertext")
      val nonce = call.argument<ByteArray>("nonce")
      val aad = call.argument<String>("aad")
      val alias = call.argument<String>("alias")
      if (ciphertext == null || nonce == null || aad == null || alias == null) {
        result.error("bad_args", "Missing ciphertext, nonce, aad, or alias.", null)
        return
      }
      if (nonce.size != ivSizeBytes) {
        result.error("decrypt_failed", "Invalid nonce size.", null)
        return
      }

      val key = getKey(alias)
        ?: run {
          result.error("key_not_found", "Key not found for alias.", null)
          return
        }
      val cipher = Cipher.getInstance(aesMode)
      cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(tagSizeBits, nonce))
      cipher.updateAAD(aad.toByteArray(StandardCharsets.UTF_8))
      val plaintext = cipher.doFinal(ciphertext)
      result.success(plaintext)
    } catch (e: Exception) {
      result.error("decrypt_failed", e.message ?: e.toString(), null)
    }
  }

  private fun handleIsStrongBoxAvailable(result: Result) {
    try {
      val available = appContext.packageManager
        .hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)
      result.success(available)
    } catch (e: Exception) {
      result.error("is_strongbox_available_failed", e.message ?: e.toString(), null)
    }
  }

  private fun getKey(alias: String): SecretKey? {
    val keyStore = KeyStore.getInstance(keyStoreType)
    keyStore.load(null)
    return keyStore.getKey(alias, null) as? SecretKey
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}

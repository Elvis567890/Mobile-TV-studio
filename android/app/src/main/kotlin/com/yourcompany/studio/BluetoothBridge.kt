package com.yourcompany.studio

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.Executors

/**
 * RFCOMM Bluetooth video transport.
 *
 * Android only. iOS does not allow this — the Dart side already
 * knows that and never calls into this bridge on iOS.
 */
class BluetoothBridge(private val context: Context) {

    companion object {
        // Fixed UUID. Both ends must use the same one.
        private val SERVICE_UUID: UUID =
            UUID.fromString("8ce255c0-200a-11e0-ac64-0800200c9a66")
    }

    private var socket: BluetoothSocket? = null
    private var output: OutputStream? = null
    private val io = Executors.newSingleThreadExecutor()

    fun isSupported(): Boolean {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return false
        return adapter.isEnabled
    }

    fun pairedDevices(): List<Map<String, String>> {
        val adapter = BluetoothAdapter.getDefaultAdapter() ?: return emptyList()
        if (!hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) return emptyList()

        val out = mutableListOf<Map<String, String>>()
        try {
            for (d in adapter.bondedDevices) {
                out.add(
                    mapOf(
                        "name" to (d.name ?: "Unknown"),
                        "mac" to d.address
                    )
                )
            }
        } catch (_: SecurityException) {}
        return out
    }

    fun connect(mac: String, result: MethodChannel.Result) {
        if (!hasPermission(Manifest.permission.BLUETOOTH_CONNECT)) {
            result.error("NO_PERMISSION", "BLUETOOTH_CONNECT is required", null)
            return
        }

        io.execute {
            try {
                val adapter = BluetoothAdapter.getDefaultAdapter()
                    ?: throw IllegalStateException("No Bluetooth adapter")

                val device: BluetoothDevice = adapter.getRemoteDevice(mac)
                adapter.cancelDiscovery()

                val s = device.createRfcommSocketToServiceRecord(SERVICE_UUID)
                s.connect()

                socket = s
                output = s.outputStream

                result.success(true)
            } catch (e: Exception) {
                result.error("BT_CONNECT_FAIL", e.message, null)
            }
        }
    }

    fun sendChunk(data: ByteArray, result: MethodChannel.Result) {
        val out = output
        if (out == null) {
            result.error("BT_NOT_CONNECTED", "No active Bluetooth connection", null)
            return
        }
        if (data.size > 990) {
            result.error("BT_CHUNK_TOO_BIG", "Chunk exceeds 990 bytes", null)
            return
        }

        io.execute {
            try {
                out.write(data)
                out.flush()
                result.success(data.size)
            } catch (e: Exception) {
                result.error("BT_WRITE_FAIL", e.message, null)
            }
        }
    }

    fun disconnect() {
        try {
            output?.close()
        } catch (_: Exception) {}
        try {
            socket?.close()
        } catch (_: Exception) {}
        output = null
        socket = null
    }

    private fun hasPermission(perm: String): Boolean {
        return ContextCompat.checkSelfPermission(context, perm) ==
                PackageManager.PERMISSION_GRANTED
    }
}
